extends Node

class_name GDS_Scheduler

var PHYSICS_DELTA_US: int = (1.0 / Engine.iterations_per_second) * 1000.0 * 1000.0 \
	setget set_forbidden

var SIMULATING := false

var all_task := {} setget set_forbidden, get_forbidden
var task_mutex := Mutex.new() setget set_forbidden, get_forbidden
var synch := Synchronizer.new() setget set_forbidden, get_forbidden


class Synchronizer extends Object:

	var iteration_delta := 0.0
	var is_in_iteration := false
	var iteration_start_at := 0
	var iteration_end_at := 0

class Task extends Object:

	const PRIME_NUMBERS := PoolIntArray([0, 2, 3, 5, 7, 11, 13, 17, 19, \
		23, 29, 31, 37, 41, 43, 47])

	var task_name := ""
	var handler := ""
	var task_lock := Mutex.new()
	var synch: Synchronizer = null
	var autofree := false
	var handling := []
	var thread_list := []
	var simulating := false

	var killsig := false
	var a := false

	func add_handle(handle: Object):
		task_lock.lock()
		handling.push_back(handle)
		task_lock.unlock()

	func has_handle(handle: Object) -> bool:
		for h in handling:
			if h.get_instance_id() == handle.get_instance_id():
				return true
		return false

	func job(id: int):
		var prime := PRIME_NUMBERS[id]
		var curr_usec := Time.get_ticks_usec()
		while not killsig:
			if not (curr_usec >= synch.iteration_start_at \
				and curr_usec < synch.iteration_end_at): continue
			var iter := 1
			var selecting := prime
			while selecting < handling.size() and not killsig \
				and task_lock.try_lock() != ERR_BUSY:
					var obj: Object = handling[selecting]
					if (not is_instance_valid(obj)): continue
					obj.call(handler, synch.iteration_delta)
					iter += 1; selecting = iter * prime
			curr_usec = Time.get_ticks_usec()

	func simulate():
		if a:
			a = false
			Out.print_debug("Awesome")
		var prime := 1
		var curr_usec := Time.get_ticks_usec()
		while not killsig:
			if not (curr_usec >= synch.iteration_start_at \
				and curr_usec < synch.iteration_end_at):
					yield(Out.get_tree(), "idle_frame")
			var iter := 1
			var selecting := 0
			while selecting < handling.size() and not killsig:
				var obj: Object = handling[selecting]
				if (not is_instance_valid(obj)): continue
				obj.call(handler, synch.iteration_delta)
				if selecting == 0:
					selecting = 1
				else:
					iter += 1; selecting = iter * prime

	func remove_handle(handle: Object):
		task_lock.lock()
		handling.erase(handle)
		task_lock.unlock()

	func boot(thread_count: int):
		if simulating:
			simulate()
			return
		if thread_count >= PRIME_NUMBERS.size():
			Out.print_fatal("Can't handle given amount of threads", get_stack())
		thread_list.resize(thread_count)
		for iter in range(0, thread_count):
			var new_thread := Thread.new()
			var err := new_thread.start(self, "job", iter)
			if err != OK:
				Out.print_error("Can't create thread: " + str(err), get_stack())
			thread_list[iter] = new_thread

	func kill_task():
		if handling.size() == 0:
			return
		killsig = true
		if not simulating:
			for thread in thread_list:
				(thread as Thread).wait_to_finish()
		thread_list.clear()
		handling.clear()

func set_forbidden(v): pass
func get_forbidden(): return null

func _init():
	synch.iteration_delta = PHYSICS_DELTA_US / 1000.0 / 1000.0

func _ready():
	pass

func _exit_tree():
	for active_task in all_task:
		all_task[active_task].kill_task()
	all_task.clear()
	synch.free()

func _physics_process(delta):
	synch.is_in_iteration = true
	synch.iteration_start_at = Time.get_ticks_usec()
	synch.iteration_end_at = synch.iteration_start_at + PHYSICS_DELTA_US

func add_task(task_name: String, handler: String, thread_count: int, \
	autofree := false) -> bool:
		if (all_task.has(task_name)): return false
		var new_task := Task.new()
		new_task.autofree = autofree
		new_task.task_name = task_name
		new_task.handler = handler
		new_task.synch = synch
		new_task.simulating = SIMULATING
		new_task.boot(thread_count)
		task_mutex.lock()
		all_task[task_name] = new_task
		task_mutex.unlock()
		return true

func has_task(task_name: String) -> bool:
	return all_task.has(task_name)

func remove_task(task_name: String) -> bool:
	task_mutex.lock()
	var re := all_task.erase(task_name)
	task_mutex.unlock()
	return re

func add_handle(task_name: String, handle: Object) -> void:
	var task: Task = all_task.get(task_name)
	if not is_instance_valid(task): return
	task.add_handle(handle)

func has_handle(task_name: String, handle: Object) -> bool:
	var task: Task = all_task.get(task_name)
	if not is_instance_valid(task): return false
	return task.has_handle(handle)

func remove_handle(task_name: String, handle: Object) -> void:
	var task: Task = all_task.get(task_name)
	if not is_instance_valid(task): return
	task.remove_handle(handle)
	if task.handling.size() == 0 and task.autofree:
		all_task.erase(task.task_name)
		task.kill_task()
		task.free()
