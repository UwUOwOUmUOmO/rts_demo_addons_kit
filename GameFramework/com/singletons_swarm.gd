extends Node

var services := {}

func add_singleton(s_name: String, path: String):
	var s_script: Script = ResourceLoader.load(path, "Script")
	var new_node := Node.new()
	if not s_name.empty():
		new_node.name = s_name
	new_node.set_script(s_script)
	call_deferred("add_child", new_node)
	services[s_name] = new_node

func add_instanced_singleton(singleton: Node):
	if is_instance_valid(singleton.get_parent()):
		Out.print_error("Singleton already has a parent", get_stack())
		return
	call_deferred("add_child", singleton)
	services[singleton.name] = singleton

func remove_singleton(s_name: String):
	var s := get_node_or_null(s_name)
	if not s:
		return
	services.erase(s.name)
	s.queue_free()

func remove_singletons(list: PoolStringArray):
	for s in list:
		remove_singleton(s)

func singleton_rename(old: String, new: String):
	var s := get_node_or_null(old)
	if not s:
		return
	services.erase(old)
	services[new] = s
	s.name = new
