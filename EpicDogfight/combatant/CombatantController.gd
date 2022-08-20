extends Node

class_name CombatantController

const DEFAULT_WEAPONS := {
	"PRIMARY": null,
	"SECONDARY": null,
}
const COMPUTER_DEFAULT_SIGNALS		:= {
	"__target_changed":			"_target_change_handler",
	"__target_defeated":		"_target_defeated_handler", 
	"__combatant_changed":		"_vessel_change_handler",
	"__lock_on_detected":		"_lock_on_handler",
	"__projectile_loose_lock":	"_loose_lock_handler",
	"__combatant_defeated":		"_vessel_defeated_handler",
}
const INSTRUMENT_DEFAULT_SIGNALS	:= {
	"__lock_on_detected":		"_lock_on_handler",
	"__projectile_loose_lock":	"_loose_lock_handler",
	"__combatant_defeated":		"_vessel_defeated_handler",
}
const COMBATANT_DEFAULT_SIGNALS		:= {
	"__combatant_out_of_hp":	"combatant_defeated_handler"
}
const TARGET_S_DEFAULT_SIGNALS		:= {
	"__combatant_out_of_hp":	"target_defeated_handler"
}

# Bridge signals
signal __lock_on_detected(source)
signal __projectile_loose_lock(source)

# Main signals
signal __target_defeated(controller)
signal __target_changed(new_target)
signal __combatant_defeated(controller)
signal __combatant_changed(new_combatant)
signal __computer_changed(controller, new_computer)
signal __instrument_changed(controller, new_instrument)

onready var processors_swarm		= SingletonManager.fetch("ProcessorsSwarm")
onready var utils_settings			= SingletonManager.fetch("UtilsSettings")

var auto_ready: bool				= true
var auto_free: bool					= true
var use_physics_process: bool		= utils_settings.use_physics_process
var green_light: bool				= false setget _set_operation
var assigned_combatant: Combatant	= null  setget _set_combatant
var target							= null  setget _set_target
var computer: CombatComputer		= null  setget _set_computer
var instrument: CombatInstrument	= null  setget _set_instrument
var cluster: ProcessorsCluster		= null
var _ref: InRef						= null
var weapons: Dictionary				= DEFAULT_WEAPONS

func _init():
	connect("__combatant_changed", self, "combatant_change_handler")

func _ready():
	_ref = InRef.new(self)
	_ref.add_to("combatant_controllers")
	cluster = processors_swarm.add_cluster(name + "_proc_cluster")

func _set_operation(fl := true):
	if fl and not green_light:
		while not cluster.is_ready:
			yield(get_tree(), "idle_frame")
		cluster.commission()
		green_light = true
		return
	if green_light and not fl:
		_finalize()

func _set_combatant(com):
	if com == assigned_combatant:
		return
	if is_instance_valid(assigned_combatant):
		Toolkits.SignalTools(assigned_combatant, self, \
			COMBATANT_DEFAULT_SIGNALS)
	if com is Combatant:
		assigned_combatant = com
		Toolkits.SignalTools.connect_from(assigned_combatant, self, \
			COMBATANT_DEFAULT_SIGNALS)
		emit_signal("__combatant_changed", com)
		auto_ready_check()

func _set_target(tar):
	if tar == target:
		return
	if is_instance_valid(target):
		Toolkits.SignalTools(target, self, \
			TARGET_S_DEFAULT_SIGNALS)
	if tar is Combatant:
		target = tar
		target._controller = self
		Toolkits.SignalTools.connect_from(target, self, \
			TARGET_S_DEFAULT_SIGNALS)
		emit_signal("__target_changed", tar)
		auto_ready_check()

func _set_computer(com):
	if com == computer:
		return
	if is_instance_valid(computer):
		Toolkits.SignalTools(self, computer, \
			COMPUTER_DEFAULT_SIGNALS)
	if com is CombatComputer:
		computer = com
		computer.controller = self
		Toolkits.SignalTools.connect_from(self, computer, \
			COMPUTER_DEFAULT_SIGNALS)
		# Emit the signal before connecting it to the new computer
		# so the old computer could clean itself up
		# while not affecting the new computer
		emit_signal("__computer_changed", self, com)
		connect("__computer_changed", computer, "_controller_computer_changed",\
			[], CONNECT_ONESHOT)
		if green_light:
			cluster.add_processor(computer)
		else:
			cluster.add_nopr(computer)
		auto_ready_check()

func _set_instrument(sen):
	if sen == instrument:
		return
	if is_instance_valid(instrument):
		Toolkits.SignalTools(self, instrument, \
			INSTRUMENT_DEFAULT_SIGNALS)
	if sen is CombatInstrument:
		instrument = sen
		Toolkits.SignalTools.connect_from(self, instrument, \
			INSTRUMENT_DEFAULT_SIGNALS)

		emit_signal("__instrument_changed", self, instrument)
		connect("__instrument_changed", instrument,\
			"_controller_instrument_changed", [], CONNECT_ONESHOT)
		if green_light:
			cluster.add_processor(instrument)
		else:
			cluster.add_nopr(instrument)
		auto_ready_check()

func setup_hardpoints():
	for type in weapons:
		var handler: WeaponHandler = weapons[type]
		if not type in assigned_combatant.hardpoints:
			if is_instance_valid(handler):
				handler.queue_free()
				weapons[type] = null
			continue
		handler.set_hardpoints(assigned_combatant.hardpoints[type])

func _set_weapon(w: WeaponConfiguration, cat := "PRIMARY"):
	var new_handler := WeaponHandler.new()
	new_handler.profile = w
	weapons[cat] = new_handler
	if is_instance_valid(assigned_combatant):
		setup_hardpoints()
	call_deferred("add_child", new_handler)
	new_handler.set_deferred("owner", self)

func _set_weapon_manual(w: WeaponHandler, cat := "PRIMARY"):
	weapons[cat] = w
	call_deferred("add_child", w)
	w.set_deferred("owner", self)

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

func combatant_change_handler(_comb):
	# weapons = DEFAULT_WEAPONS
	setup_hardpoints()

func lock_on_handler(source, _tar):
	emit_signal("__lock_on_detected", source)

func loose_lock_handler(source, _tar):
	emit_signal("__projectile_loose_lock", source)

func target_defeated_handler(_tar):
	emit_signal("__target_defeated", self)

func combatant_defeated_handler(_comb):
	emit_signal("__combatant_defeated", self)
	if auto_free:
		cluster.decommission()
		_finalize()
		queue_free()

func _finalize():
	_clean()

func _clean():
	pass
