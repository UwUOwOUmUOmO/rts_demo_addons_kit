extends Control

# Specialized State Machine
class_name MCMaintainer

const MAINTAINER_DEFAULT_SIGNALS := {
	"__state_pushed": "_state_pushed_handler",
	"__state_popped": "_state_popped_handler"
}

signal __no_state()
signal __state_pushed(s)
signal __state_popped(s)

export(String) var focus_trigger := "game_pause"
export(bool) var allow_no_state := true

var default_state: MenuComponent = null
var current: MenuComponent = null setget set_curr, get_curr
var states := []
var all_states := {}

func failed_handler():
	if all_states == {}:
		set_process_unhandled_input(false)
		Out.print_error("No MenuComponent found", get_stack())

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	connect("__no_state", self, "_no_state_handler")
	_setup()

func _unhandled_input(event):
	if focus_trigger.empty():
		return
	if event.is_action_pressed(focus_trigger):
		if states == []:
			_focus_no_state()
		else:
			_focus_default()

func _no_state_handler():
	pass

func _focus_no_state():
	pass

func _focus_default():
	if states.size() == 1 and not allow_no_state:
		return
	pop_state()

func _setup():
	var all_children = get_children()
	for c in all_children:
		if c is MenuComponent:
			if default_state == null:
				default_state = c
			all_states[c.name] = c
			c.visible = false
			c.uicm = self
			Utilities.SignalTools.connect_from(self, c, MAINTAINER_DEFAULT_SIGNALS)
	failed_handler()
	visible = false

func push_default():
	if all_states.size() == 0:
		return
	push_state(default_state)
	default_state.visible = true

func push_state(s: MenuComponent):
	if states.size() > 0:
		states.back().focus = false
	states.push_back(s)
	s.focus = true
	emit_signal("__state_pushed", s)

func push_with_key(k: String):
	if not all_states.has(k):
		Out.print_error("This MCM does not have MC with name: " + k,\
			get_stack())
		return
	push_state(all_states[k])

func pop_state():
	var last_state: MenuComponent = states.pop_back()
	last_state.focus = false
	if states.empty():
		emit_signal("__no_state")
	else:
		states[states.size() - 1].focus = true
	emit_signal("__state_popped", last_state)

func set_curr(c):
	pass

func get_curr():
	return states.back()
