extends Reference

class_name DataBridgeStandalone

var wref: WeakRef = null setget set_forbidden, get_forbidden
var is_node := false setget set_forbidden, get_forbidden
var fallback_value: Object = null
var fallback_method := funcref(self, "default_fallback_evaluation")

func _init(default_fallback = null, target: Object = null):
	fallback_value = default_fallback
	if target != null:
		set_target(target)

static func default_fallback_evaluation(ref: WeakRef, is_node := false):
	if is_node:
		return is_instance_valid(ref.get_ref())
	else:
		return ref.get_ref() == null

func set_target(new_target: Object):
	wref = weakref(new_target)
	is_node = new_target is Node

func fetch():
	if fallback_method.call_funcv([wref, is_node]):
		return wref.get_ref()
	else:
		return fallback_value

func set_forbidden(s): pass

func get_forbidden():  return null
