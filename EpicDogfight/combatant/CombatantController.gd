extends Node

class_name CombatantController

signal __target_defeated(controller)
signal __target_changed(new_target)
signal __combatant_changed(new_combatant)
signal __computer_changed(controller, new_computer)
signal __instrument_changed(controller, new_instrument)

var auto_ready: bool				= true
var use_physics_process: bool		= SingletonManager.fetch("UtilsSettings").use_physics_process
var green_light: bool				= false setget _set_operation
var assigned_combatant: Combatant	= null  setget _set_combatant
var target							= null  setget _set_target
var computer: CombatComputer		= null  setget _set_computer
var instrument: CombatInstrument	= null  setget _set_instrument
var weapons := {
	"PRIMARY": null
 }


func _set_operation(fl := true):
	if fl and not green_light:
		_boostrap()
		green_light = true
		return
	if green_light and not fl:
		_finalize()

func _set_combatant(com):
	if com is Combatant and not com == assigned_combatant:
		assigned_combatant = com
		emit_signal("__combatant_changed", com)
		auto_ready_check()

func _set_target(tar):
	if tar is Combatant and not tar == target:
		target = tar
		target._controller = self
		emit_signal("__target_changed", tar)
		auto_ready_check()

func _set_computer(com):
	if com == computer:
		return
	if is_instance_valid(computer):
		disconnect("__target_changed", computer, "_target_change_handler")
		disconnect("__target_defeated", computer, "_target_defeated_handler")
		disconnect("__combatant_changed", computer, "_vessel_change_handler")
	if com is CombatComputer:
		computer = com
		computer.controller = self
		connect("__target_changed", computer, "_target_change_handler")
		connect("__target_defeated", computer, "_target_defeated_handler")
		connect("__combatant_changed", computer, "_vessel_change_handler")
		# Emit the signal before connecting it to the new computer
		# so the old computer could clean itself up
		# while not affecting the new computer
		emit_signal("__computer_changed", self, com)
		connect("__computer_changed", computer, "_controller_computer_changed",\
			[], CONNECT_ONESHOT)
		auto_ready_check()
	

func _set_instrument(sen):
	if sen is CombatInstrument and not sen == instrument:
		instrument = sen
		connect("__instrument_changed", instrument,\
			"_controller_instrument_changed", [], CONNECT_ONESHOT)
		emit_signal("__instrument_changed", self, sen)
		auto_ready_check()

func auto_ready_check():
	if auto_ready:
		if not is_instance_valid(assigned_combatant):
			return
		elif not is_instance_valid(target):
			return
		elif not is_instance_valid(computer):
			return
		elif not is_instance_valid(instrument):
			return
		_set_operation()

func _boostrap():
	computer.host = self
	instrument.host = self
	computer._boot()
	instrument._boot()

func _target_defeated_check():
	if is_instance_valid(target):
		return
	elif target.hp > 0.0:
		return
	emit_signal("__target_defeated", self)

func _compute(delta: float):
	_target_defeated_check()
	computer._compute(delta)
	instrument._compute(delta)

func _process(delta):
	if not use_physics_process and green_light:
		_compute(delta)

func _physics_process(delta):
	if use_physics_process and green_light:
		var fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta
		_compute(fixed_delta)

func _finalize():
	_clean()

func _clean():
	pass
