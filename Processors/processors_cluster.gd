extends Node

class_name ProcessorsCluster

var is_ready			:= false
var is_commissioned     := false
var auto_remove         := true
var _ref: InRef          = null

var cluster := []

var boot_mutex			:= Mutex.new()
var cluster_mutex		:= Mutex.new()

func _ready():
	_ref = InRef.new(self)
	_ref.add_to("processor_swarm")
	is_ready = true

func add_processor(proc: Processor):
	if is_commissioned:
		boot_mutex.lock()
	cluster_mutex.lock()
	if not proc.enforcer_assigned:
		cluster.append(proc)
		proc.enforcer_assigned = true
		if is_commissioned:
			proc.host = self
			proc._boot()
	cluster_mutex.unlock()
	if is_commissioned:
		boot_mutex.unlock()

func add_nopr(proc: Processor):
	cluster_mutex.lock()
	if not proc.enforcer_assigned:
		cluster.append(proc)
		proc.enforcer_assigned = true
	cluster_mutex.unlock()

func decommission():
	is_commissioned = false
	cluster_mutex.lock()
	for proc in cluster:
		proc.terminated = true
	cluster = []
	cluster_mutex.unlock()
	if auto_remove:
		queue_free()

func commission():
	boot_mutex.lock()
	for proc in cluster:
		proc.host = self
		proc._boot()
	boot_mutex.unlock()
	is_commissioned = true

func _process(delta):
	compute(delta)

func _physics_process(delta):
	compute(delta, true)

func compute(delta: float, pp := false):
	if not is_commissioned:
		return
	for proc in cluster:
		if proc.terminated:
			continue
		if proc.use_physics_process and pp:
			proc._compute(delta)
		elif not proc.use_physics_process and not pp:
			proc._compute(delta)
