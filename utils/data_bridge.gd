extends Reference

class_name DataBridge

var host: Object = null
var pname := ""
var fallback_value = null
var fallback_method := funcref(Utilities.TrialTools, "default_fallback_evaluation")

func _init(default_fallback = null, target: Object = null, property_name := ""):
	fallback_value = default_fallback
	host = target
	if property_name.empty():
		Out.print_error("Property name is not supposed to be empty", get_stack())
	pname = property_name

func read():
	if fallback_method.call_funcv([host, pname]):
		return host.get(pname)
	else:
		return fallback_value

func write(new_value):
	if fallback_method.call_funcv([host, pname]):
		host.set(pname, new_value)
