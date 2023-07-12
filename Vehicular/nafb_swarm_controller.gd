extends Node

var COMPUTE_DELAY: int = clamp(ProjectSettings.get_setting("game/compute_delay"), 1, 5)

var instance_pool := []
# var id_pool := PoolIntArray()
var main_lock := RWLock.new()

func add_nafb_instance(instance):
	main_lock.write_lock()
	# id_pool.push_back(instance.get_instance_id())
	instance_pool.append(instance)
	main_lock.write_unlock()

func remove_nafb_instance(instance):
	main_lock.write_lock()
	# var id := id_pool.find(instance.get_instance_id())
	# if id != -1:
	# 	id_pool.remove(id)
	instance_pool.erase(instance)
	main_lock.write_unlock()

func _physics_process(delta):
	var frame_no := Engine.get_physics_frames()
	main_lock.read_lock()
	if frame_no % COMPUTE_DELAY == 0:
		var real_delta: float = delta * COMPUTE_DELAY
		for instance in instance_pool:
			instance.enforce_all(real_delta)
		for instance in instance_pool:
			instance.nafb_command_queue.sync()
			instance.nafb_command_queue.call_dispatched("job", real_delta)
	main_lock.read_unlock()
