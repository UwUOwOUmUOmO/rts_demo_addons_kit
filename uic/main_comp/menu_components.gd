extends Control

class_name MenuComponent

var uicm = null
var focus := false setget set_focus

func set_focus(f: bool):
	focus = true
	# if auto_hide:
	# 	visible = f
	# if f:
	# 	_in_focus()
	# else:
	# 	_out_focus()

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	_setup()

func _process(delta):
	_idle(delta)

func _setup():
	pass

func _state_pushed_handler(state):
	if state == self:
		_self_pushed()
	else:
		_non_self_pushed()

func _state_popped_handler(state):
	if state == self:
		_self_popped()
	else:
		_non_self_popped()

func _non_self_pushed():
	pass

func _self_pushed():
	pass

func _non_self_popped():
	pass

func _self_popped():
	pass

func _idle(delta: float):
	pass
