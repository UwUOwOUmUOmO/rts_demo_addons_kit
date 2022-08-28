extends Serializable

class_name StateSingular

const STATE_SINGULAR_SIGNALS := {
	"__state_added": "state_machine_pushed_handler",
	"__state_removed": "state_machine_popped_handler"
}

# Persistent
var state_name := ""
var exclusive := false

# Volatile
var current_machine = null
var next_state = null setget , _get_next_state

func _init():
	name = "StateSingular"
	remove_properties(["next_state", "current_machine"])

func _get_next_state():
	if not exclusive:
		return next_state
	return null

func blackboard_set(index: String, value):
	if current_machine:
		current_machine.blackboard_set(index, value)

func blackboard_get(index: String):
	if current_machine:
		return current_machine.blackboard_get(index)
	return null

func state_machine_pushed_handler(machine, _name, s_ref):
	if s_ref == self:
		current_machine = machine
		_boot()

func state_machine_popped_handler(machine, _name, s_ref):
	if s_ref == self:
		next_state = null
		Utilities.SignalTools.disconnect_from(machine, self, \
			STATE_SINGULAR_SIGNALS)
		_finalize()

func pop():
	Utilities.TrialTools.try_call(current_machine, "remove_state_by_name", \
		[state_name])

func _boot():
	pass

func _compute(delta: float):
	return null

func _finalize():
	pass
