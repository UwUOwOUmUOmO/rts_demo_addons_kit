extends Configuration

class_name Processor

# Volatile
var host = null setget _set_host
var tree: SceneTree = null setget _set_tree
var terminated := false
var enforcer_assigned := false

# Persistance
export(bool) var use_physics_process: bool = SingletonManager.fetch("UtilsSettings").use_physics_process

func _set_host(h):
	host = h

func _set_tree(t):
	tree = t

func _init():
	._init()
	# exclusion_list.append_array(["host", "tree", "terminated",\
	# 	"enforcer_assigned"])
	remove_properties(["host", "tree", "terminated",\
		"enforcer_assigned"])
	name = "Processor"
	return self

func _boot():
	pass

func _compute(delta: float):
	pass

