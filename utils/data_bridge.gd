extends Reference

class_name DataBridge

var host: Object = null
var pname := ""
var fallback_value = null
var fallback_method := funcref(self, "default_fallback_evaluation")

func _init(default_fallback = null, target: Object = null, property_name := ""):
	fallback_value = default_fallback
	host = target
	if property_name.empty():
		Out.print_error("Property name is not supposed to be empty", get_stack())
	pname = property_name

static func default_fallback_evaluation(target, property_name: String):
	if not target is Object or not is_instance_valid(target):
		return false
	if not property_name in target:
		return false
	return true

static func try_set(target: Object, prop: String, value):
	var path: Array = Toolkits.PathTools.slice_path(prop, ['.'])
	var final_prop = path.pop_back()
	var final_path := Toolkits.PathTools.join_path(path, '.')
	var final_instance = try_get(target, final_path)
	if default_fallback_evaluation(final_instance, final_prop):
		final_instance.set(final_prop, value)

static func try_get(target: Object, prop: String, next_to_final := false):
	var instance := target
	var path: Array = Toolkits.PathTools.slice_path(prop, ['.'])
	if next_to_final:
		path.pop_back()
	var curr_prop = path.pop_front()
	while curr_prop != null and instance is Object:
		if curr_prop in instance:
			instance = instance.get(curr_prop)
		else:
			instance = null
		curr_prop = path.pop_front()
	return instance

static func try_append(target: Object, prop: String, value):
	var instance = try_get(target, prop)
	if instance is Array:
		instance.append(value)

func read():
	if fallback_method.call_funcv([host, pname]):
		return host.get(pname)
	else:
		return fallback_value

func write(new_value):
	if fallback_method.call_funcv([host, pname]):
		host.set(pname, new_value)
