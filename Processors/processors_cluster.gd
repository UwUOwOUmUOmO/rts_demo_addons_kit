extends Node

class_name ProcessorsCluster

var is_ready			:= false
var is_commissioned		:= false setget set_commissioned
var auto_free_cluster	:= true
var _ref: InRef			 = null

var host = null
var cluster := []
var auto_commission := false

var boot_mutex			:= Mutex.new()
var cluster_mutex		:= Mutex.new()

var multithreading := false
var thread_list_idle := []
var thread_list_physics := []
var allocated_clusters := {}
var max_thread_count := 8
var current_physics_call := 0
var thread_count := 0
var allocating := 0
var shutdown_all := false

var idle_delta := 0
var physics_delta := 0

func _init(auto := false):
	auto_commission = auto

func _ready():
	_ref = InRef.new(self)
	_ref.add_to("processor_swarm")
	is_ready = true
	if auto_commission:
		set_commissioned(true)

func _exit_tree():
	decommission()
	for t in thread_list_idle:
		t.wait_to_finish()
	for t in thread_list_physics:
		t.wait_to_finish()
	host = null
	cluster = []
	boot_mutex = null
	cluster_mutex = null
	thread_list_idle = []
	thread_list_physics = []
	allocated_clusters = {}

func set_commissioned(c: bool):
	if c:
		commission()
	else:
		decommission()

func add_processor(proc: Processor):
#	if is_commissioned and multithreading:
#		Out.print_warning("Can't add processor while multiple cluster threads are running")
#		return
	if is_commissioned:
		boot_mutex.lock()
	cluster_mutex.lock()
	if not proc.enforcer_assigned:
		cluster.append(proc)
		proc.host = host
		proc.enforcer = self
		if is_commissioned:
			proc._boot()
	cluster_mutex.unlock()
	if is_commissioned:
		boot_mutex.unlock()
		if multithreading:
			allocate_processor(proc)

func add_processor_no_boot(proc: Processor):
#	if is_commissioned and multithreading:
#		Out.print_warning("Can't add processor while multiple cluster threads are running")
#		return
	cluster_mutex.lock()
	if not proc.enforcer_assigned:
		cluster.append(proc)
		proc.host = host
		proc.enforcer = self
	cluster_mutex.unlock()
	if is_commissioned and multithreading:
		allocate_processor(proc)

func decommission():
	if not is_commissioned:
		return
	is_commissioned = false
	shutdown_all = true
	cluster_mutex.lock()
	for proc in cluster:
		proc.terminated = true
	cluster = []
	cluster_mutex.unlock()
	if auto_free_cluster:
		queue_free()

func commission():
	if multithreading:
		multithreads_distribute()
		for c in cluster:
			allocate_processor(c)
	boot_mutex.lock()
	for proc in cluster:
		proc._boot()
	boot_mutex.unlock()
	is_commissioned = true

func multithreads_distribute():
	if get_parent() == null:
		get_tree().quit(-1)
	if thread_list_idle.size() > 0:
		return
	# Out.print_debug("Woop Woop", get_stack())
	var processor_count := OS.get_processor_count()
	thread_count = clamp(processor_count / 2, 1, max_thread_count)
	if thread_count == 1:
		multithreading = false
		commission()
		return
	if thread_count % 2 != 0:
		thread_count += 1
	var iter := 0
	while iter < thread_count:
		var it := Thread.new()
		var pt := Thread.new()
		it.start(self, "idle_worker", iter)
		pt.start(self, "physics_worker", iter)
		thread_list_idle.append(it)
		thread_list_physics.append(pt)
		# -----------------------------
		allocated_clusters[iter] = []
		allocated_clusters[iter + 1] = []
		# Out.print_debug("Allocating thread no. " + str(iter) + " and " + str(iter + 1))
		iter += 2
	pass

func allocate_processor(proc: Processor):
	cluster_mutex.lock()
	if not proc in allocated_clusters[allocating]:
		allocated_clusters[allocating].append(proc)
		allocating = wrapi(allocating + 1, 0, thread_count)
	cluster_mutex.unlock()

func _process(delta):
	idle_delta = delta
	if multithreading:
		var iter := 0
		var size := thread_list_idle.size()
		while iter < size:
			var thread: Thread = thread_list_idle[iter]
			if thread.is_alive():
				thread.wait_to_finish()
			thread = Thread.new()
			thread.start(self, "physics_worker", iter)
			thread_list_physics[iter] = thread
			iter += 1
		return
	compute(delta)

func _physics_process(delta):
	physics_delta = delta
	current_physics_call += 1
	if multithreading:
		var iter := 0
		var size := thread_list_physics.size()
		while iter < size:
			var thread: Thread = thread_list_physics[iter]
			if thread.is_alive():
				thread.wait_to_finish()
			thread = Thread.new()
			thread.start(self, "physics_worker", iter)
			thread_list_physics[iter] = thread
			iter += 1
		return
	compute(delta, true)

func compute(delta: float, pp := false, procs := cluster):
	# return
	if not is_commissioned:
		return
	for proc in procs:
		if proc.terminated:
			return
		if proc.use_physics_process and pp:
			proc._compute(delta)
		elif not proc.use_physics_process and not pp:
			proc._compute(delta)

func idle_worker(tid: int):
	# var current_frame := get_tree().get_frame()
	# var last_usec := Time.get_ticks_usec()
	# var count := 0
	# while true:
	# 	if shutdown_all:
	# 		return
	# 	while current_frame == get_tree().get_frame():
	# 		pass
	# 	# ------------------------------------
	# 	current_frame = get_tree().get_frame()
	# 	var curr_usec := Time.get_ticks_usec()
	# 	var delta := (curr_usec - last_usec) / 1000.0
	# 	compute(delta, false, allocated_clusters[tid])
	# 	last_usec = curr_usec
	# 	count += 1
	# 	if count > 2:
	# 		return
	compute(idle_delta, false, allocated_clusters[tid])

func physics_worker(tid: int):
# #	print("Physics Worker")
# 	var current_frame := current_physics_call
# 	var last_usec := Time.get_ticks_usec()
# #	var printed := false
# 	while true:
# 		if shutdown_all:
# 			print("Shutting down")
# 			return
# 		while current_frame == current_physics_call:
# 			pass
# 		# ------------------------------------
# 		current_frame = current_physics_call
# 		var curr_usec := Time.get_ticks_usec()
# 		var delta := (curr_usec - last_usec) / 1000.0
# #		if not printed:
# #			print("Pre compute")
# 		compute(delta, true, allocated_clusters[tid])
# #		if not printed:
# #			print("Post compute")
# #			printed = true
# 		last_usec = curr_usec
	compute(physics_delta, true, allocated_clusters[tid])
