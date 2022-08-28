extends StateMachine

class_name WorkerStateMachine

const WSM_SIGNALS := {
	"urgent_edict": "edicts_refetch_handler"
}

# Persistent

# Volatile
var all_edicts := {}
var director = null setget set_director

func _init():
	name = "WorkerStateMachine"
	remove_properties(["all_edicts", "director"])

func _object_deserialized():
	._object_deserialized()
	pass

func set_director(d):
	director = d
	force_edicts_reset()

func edicts_refetch_handler(_e):
	force_edicts_reset()

func force_edicts_reset():
	all_edicts = director.get_edicts_chain()
	# all_edicts = Utilities.TrialTools.try_call(director, \
	# 	"get_edicts_chain", [], {})

func edict_process(delta: float) -> bool:
	if all_edicts == {}:
		return false
	var stack_count := 0
	var forbid_substates := false
	for state_name in all_edicts:
		if is_paused or terminated or stack_count >= MAX_STACK:
			break
		var state: Edicts = all_edicts[state_name]
		state._edict_execute(delta, host)
		forbid_substates = forbid_substates or state.forbid_substates
		if state.exclusive:
			break
		stack_count += 1
	return forbid_substates

func _compute(delta: float):
	if not edict_process(delta):
		._compute(delta)
