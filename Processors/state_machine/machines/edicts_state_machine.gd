extends StateMachine

# This is an abstract class, please do not use this unironically
# Ok maybe please do
class_name EdictsStateMachine

const ESM_SIGNALS := {
	"__edict_issued": "edict_addition_handler",
	"__edict_removed": "edict_removal_handler",
	"__edicts_refetch": "edicts_refetch_handler",
}

signal __edict_issued(machine, edict_name, edict)
signal __edict_removed(machine, edict_name, edict)
signal __edicts_refetch(edict)

# Persistent
var grade := 0

# Volatile
var director = null setget set_director

func _init():
	name = "EdictsStateMachine"
	remove_properties(["director"])
	add_state(EdictIdle.new())
	# is_paused = true

func set_director(d):
	if director != null:
		Utilities.SignalTools.disconnect_from(director, self, \
			ESM_SIGNALS, false)
	director = d
	# Utilities.SignalTools.connect_from(director, self, \
	# 	WSM_SIGNALS, true, false)
	Utilities.SignalTools.connect_from(director, self, \
		ESM_SIGNALS, true, false)

func edicts_refetch_handler(_e):
	# emit_signal("__edicts_refetch", e)
	pass

func issue_edict(edict: Edicts):
	emit_signal("__edict_issued", self, edict, edict.state_name)

func remove_edict(edict: Edicts):
	emit_signal("__edict_removed", self, edict, edict.state_name)

func edict_addition_handler(machine, _edict_name, edict: Edicts):
	if not machine == director:
		return
	var approval := true
	for e in states_pool:
		approval = approval and e.edict_approve(edict)
		if not approval:
			return
	var edict_dup = config_duplicate(false)
	if edict.prioritized:
		insert_state(edict_dup, "Idle")
	else:
		add_state(edict_dup)

func edict_removal_handler(machine, edict_name: String, _edict):
	if not machine == director:
		return
	remove_state_by_name(edict_name)

func add_state(s: StateSingular):
	if s is Edicts:
		if s.force_edicts_refetch: emit_signal("__edicts_refetch", s)
		.add_state(s)

func add_state_prioritized(s: StateSingular):
	if s is Edicts:
		if s.force_edicts_refetch: emit_signal("__edicts_refetch", s)
		.add_state_prioritized(s)

func insert_state(s: StateSingular, after: String):
	if s is Edicts:
		if s.force_edicts_refetch: emit_signal("__edicts_refetch", s)
		.insert_state(s, after)

# func _compute(_delta):
# 	return null
