extends Node

const DEFAULT_AUTOLOAD := PoolStringArray([
	"res://addons/utils/singletons/core_settings.gd",
	"res://addons/utils/singletons/cfg_serializer.gd",
])
const DEFAULT_AUTOLOAD_NAME := PoolStringArray([
	"UtilsSettings",
	"ConfigSerializer"
])

var local_singletons_swarm: Node = null

var services := {} setget set_services, get_services
var static_services := {}

# func _exit_tree():
# 	print("\tSTRAY NODES")
# 	print_stray_nodes()

func _ready():
	var size = DEFAULT_AUTOLOAD.size()
	var iter := 0
	for count in range(0, size):
		add_static_from_script(DEFAULT_AUTOLOAD[count],\
			DEFAULT_AUTOLOAD_NAME[count])

func set_services(s):
	return

func get_services():
	return local_singletons_swarm.services

func fetch(name: String):
	if static_services.has(name):
		return static_services[name]
	if local_singletons_swarm.services.has(name):
		return local_singletons_swarm.services[name]
	Out.print_error("Service not exist: " + name,
		get_stack())
	return null

func remove_single(s_name: String) -> void:
	local_singletons_swarm.remove_singleton(s_name)

func remove_multiple(queued: PoolStringArray) -> void:
	local_singletons_swarm.remove_singletons(queued)

func remove(ser) -> void:
	if ser is String:
		remove_single(ser)
	elif ser is PoolStringArray or ser is Array:
		remove_multiple(ser)
	Out.print_error("Input argument is neither Array nor String", \
		get_stack())

func add_singleton(singleton: Node):
	local_singletons_swarm.add_instanced_singleton(singleton)

func add_singleton_from_script(script_loc: String, s_name := ""):
	local_singletons_swarm.add_singleton(s_name, script_loc)

func add_static(singleton: Node):
	if is_instance_valid(singleton.get_parent()):
		Out.print_error("Singleton already has a parent", get_stack())
		return
	call_deferred("add_child", singleton)
	singleton.set_deferred("owner", self)
	static_services[singleton.name] = singleton

func add_static_from_script(script_loc: String, s_name: String):
	var s_script: Script = ResourceLoader.load(script_loc, "Script")
	var new_node := Node.new()
	if s_name.empty():
		Out.print_error("Static singleton must have non-empty name", get_stack())
		new_node.free()
		return
	new_node.name = s_name
	new_node.set_script(s_script)
	call_deferred("add_child", new_node)
	new_node.set_deferred("owner", self)
	static_services[s_name] = new_node
