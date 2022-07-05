extends Configuration

class_name Processor

signal __processor_terminated(proc)

# Volatile
var host = null setget _set_host
var tree: SceneTree = null setget _set_tree
var terminated := false setget set_terminated
var enforcer_assigned := false

# Persistance
export(bool) var use_physics_process: bool = SingletonManager.fetch("UtilsSettings")\
	.use_physics_process

func set_terminated(t: bool):
	if t:
		emit_signal("__processor_terminated", self)
	terminated = t

func _set_host(h):
	host = h

func _set_tree(t):
	tree = t

func _init():
	# 
	remove_properties(["host", "tree", "terminated",\
		"enforcer_assigned"])
	name = "Processor"
	connect("__processor_terminated", self, "_termination_handler")
	return self

func _boot():
	pass

func _compute(delta: float):
	pass

func _termination_handler(_proc):
	pass
