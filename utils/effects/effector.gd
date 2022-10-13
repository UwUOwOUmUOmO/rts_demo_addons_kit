extends Serializable

class_name Effector

const SERIALIZABLE_SIGNALS := {
	"changed": "host_changed_handler",
}

# Persistent
var original_value := {}
var modified_value := {}
var effects_pool := {}
var host = null setget set_host

# Volatile
var snapshot := MaunalSnapShot.new()

func _init():
	name = "Effector"

func set_host(h):
	if is_instance_valid(host):
		Utilities.SignalTools.disconnect_from(host, self, SERIALIZABLE_SIGNALS, false)
	host = h
	snapshot.host = h
	Utilities.SignalTools.connect_from(host, self, SERIALIZABLE_SIGNALS, false)

func update():
	original_value = snapshot.snap()

func add_effect(eff):
	var category_name: String = eff.category_name
	if not original_value.has(category_name):
		return
	var effect_name: String = eff.effect_name
	if not effects_pool.has(category_name):
		effects_pool[category_name] = {}
	if not effects_pool[category_name].has(effect_name):
		effects_pool[category_name][effect_name] = eff
	update_property(category_name, eff)

func update_property(property: String, eff = null):
	var original = original_value[property]
	var new_value = modified_value[property]
	# Avoid unecessarily trigger "changed" signal
	if eff != null:
		new_value = eff.take_effect(original, new_value)
	else:
		for effeft in effects_pool:
			new_value = effeft.take_effect(original, new_value)
	if modified_value[property] != new_value:
			modified_value[property] = new_value

func fetch(property: String):
	return modified_value.get(property)

func change(property: String, value):
	modified_value[property] = value

func host_changed_handler():
	update()
	var changes := snapshot.changes
	for change in changes:
		if change in effects_pool:
			update_property(change)
