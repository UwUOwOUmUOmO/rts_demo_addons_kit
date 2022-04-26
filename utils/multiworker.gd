extends Reference

class_name MultiWorker

var tree: SceneTree = null

var workers_count := 0 setget set_workers_count, get_workers_count
var init_lookup := PoolIntArray()
var threads_array := []
var last_values := []
var fref: FuncRef = null
var args := []
var ebreak := false

func _init():
	if workers_count > 0:
		set_workers_count(workers_count)

func reset_all_values():
	for c in range(0, last_values.size()):
		reset_value(c)

func reset_value(no: int):
	last_values[no] = null

func start_all():
	for c in range(0, init_lookup.size()):
		start(c)

func start(no: int):
	init_lookup[no] = 1

func worker(no: int):
	var re = null
	while true:
		if ebreak:
			break
		if init_lookup[no] == -1:
			# Break and return last return
			return re
		elif init_lookup[no] == 1:
			# run the function and flip the swicth
			if fref:
				print("aaa")
				if args[no] == null or not args[no] is Array:
					re = fref.call_func()
				elif args[no] is Array:
					re = fref.call_funcv(args[no])
				last_values[no] = re
			init_lookup[no] = 0
	
func return_all_threads() -> Array:
	var return_array := []
	for c in range(0, threads_array.size()):
		return_array.append(catch_thread(c))
	return return_array

func catch_thread(no: int):
	var thread: Thread = threads_array[no]
	init_lookup[no] = -1
	while thread.is_alive():
		if ebreak:
			break
		yield(tree, "idle_frame")
	return thread.wait_to_finish()

func set_workers_count(count: int):
	if count < 0:
		return null
	var delta := count - workers_count
	var return_array := []
	if delta < 0:
		# New count is smaller than old one, relieve some threads
		for c in range(count, workers_count):
			init_lookup[c] = -1
			return_array.append(catch_thread(c))
		init_lookup.resize(count)
	elif delta > 0:
		# Add new threads
		init_lookup.resize(count)
		var new_threads_count := abs(delta)
		for c in range(0, new_threads_count):
			var t := Thread.new()
			t.start(self, "worker", c)
			threads_array.append(t)
	last_values.resize(count)
	args.resize(count)
	workers_count = count
	if not return_array.empty():
		return return_array
	return null

func get_workers_count():
	return workers_count
