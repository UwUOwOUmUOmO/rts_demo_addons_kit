extends Configuration

class_name ModifiedFuncRef

# Volatile
var script_instance: Object = null
var fref: FuncRef = null

# Persistent
var script_path := ""
var base_type   := ""
var func_name   := ""

# Modified FuncRef created to be serializable
func _init():
	
	remove_properties(["script_instance", "fref"])
	name = "ModifiedFuncRef"

func __is_mod_fr():
	return true

func instance_script_object():
	if not ResourceLoader.exists(script_path):
		Out.print_error("No resource at path: " + script_path, \
			get_stack())
		return
	var target_script = load(script_path)
	if not target_script is Script:
		Out.print_error("Resource at path {p} is not a Script"\
			.format({"p": script_path}), get_stack())
		return
	elif not ClassDB.can_instance(base_type):
		Out.print_error("Can't instance object of type: " + base_type, \
			get_stack())
	script_instance = ClassDB.instance(base_type)
	script_instance.set_script(target_script)
	fref = funcref(script_instance, func_name)

func deserialize(config: Dictionary):
	.deserialize(config)
	instance_script_object()

func copy(from: Configuration) -> bool:
	var re := .copy(from)
	instance_script_object()
	return re

func fref_check() -> bool:
	if not is_instance_valid(fref) or fref == null:
		Out.print_error("Can't access fref", get_stack())
		return false
	return true

func call_func(prop):
	if not fref_check():
		return
	return fref.call_func(prop)

func call_funcv(prop: Array):
	if not fref_check():
		return
	return fref.call_funcv(prop)
