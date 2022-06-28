extends Node

const DEFAULT_AUTOLOAD := PoolStringArray([
	"res://addons/GameFramework/level_singleton.gd",
	"res://addons/Processors/processors_swarm.gd",
	"res://addons/utils/path_utils.gd",
	"res://addons/utils/core_settings.gd",
])
const DEFAULT_AUTOLOAD_NAME := PoolStringArray([
	"LevelSingleton",
	"ProcessorsSwarm",
	"PathUtils",
	"UtilsSettings"
])

var services := {}

func _ready():
	var iter := 0
	var size = DEFAULT_AUTOLOAD.size()
	for count in range(0, size):
		add_singleton_from_script(DEFAULT_AUTOLOAD[count],\
			DEFAULT_AUTOLOAD_NAME[count])

func fetch(name: String):
	if services.has(name):
		return services[name]
	Out.print_error("Service not exist: " + name,
		get_stack())
	return null

func add_singleton(singleton: Node):
	if is_instance_valid(singleton.get_parent()):
		singleton.get_parent().remove_child(singleton)
	add_child(singleton)

func add_singleton_from_script(script_loc: String, name := ""):
	var s = load(script_loc)
	if not s is Script:
		Out.print_error("Resource at {path} is not a script"\
			.format({"path": script_loc}), get_stack())
		return
	elif s.get_instance_base_type() != "Node":
		Out.print_error("Singleton at {path} must extend on type Node"\
			.format({"path": script_loc}), get_stack())
		return
	var singleton := Node.new()
	singleton.set_script(s)
	if not name.empty():
		singleton.name = name
	add_child(singleton)
	services[name] = singleton
