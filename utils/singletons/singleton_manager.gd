extends Node

const DEFAULT_AUTOLOAD := PoolStringArray([
	"res://addons/GameFramework/level_manager.gd",
	"res://addons/utils/singletons/path_utils.gd",
	"res://addons/utils/singletons/core_settings.gd",
	# "res://addons/Processors/processors_swarm.gd",
])
const DEFAULT_AUTOLOAD_NAME := PoolStringArray([
	"LevelManager",
	"PathUtils",
	"UtilsSettings",
	# "ProcessorsSwarm",
])

var services := {}
var ready := false

func _ready():
	var iter := 0
	var size = DEFAULT_AUTOLOAD.size()
	for count in range(0, size):
		add_singleton_from_script(DEFAULT_AUTOLOAD[count],\
			DEFAULT_AUTOLOAD_NAME[count])
	ready = true

func fetch(name: String):
	while not ready:
		pass
	if services.has(name):
		return services[name]
	Out.print_error("Service not exist: " + name,
		get_stack())
	return null

func remove_single(s_name: String) -> void:
	var service := get_node_or_null(s_name)
	if not is_instance_valid(service):
		Out.print_error("Service does not exist: " + s_name, \
			get_stack())
		return
	service.queue_free()

func remove_multiple(queued: Array) -> void:
	for s_name in queued:
		remove_single(s_name)

func remove(ser) -> void:
	if ser is String:
		remove_single(ser)
	elif ser is PoolStringArray or ser is Array:
		remove_multiple(ser)
	Out.print_error("Input argument is neither Array nor String", \
		get_stack())

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
