extends Configuration

class_name Processor

# Volatile
var host = null setget _set_host
var tree: SceneTree = null setget _set_tree
var terminated := false
var enforcer_assigned := false

# Persistance
export(bool) var use_physics_process := true

func _set_host(h):
	host = h

func _set_tree(t):
	tree = t

func _init():
	exclusion_list.append_array(["host", "tree", "terminated",\
		"enforcer_assigned"])
	._init()
	name = "Processor"
	return self

func _process(delta: float):
	if not use_physics_process:
		_compute(delta)

func _physics_process(delta: float):
	if use_physics_process:
		_compute(delta)

func _boot():
	pass

func _compute(delta: float):
	pass

