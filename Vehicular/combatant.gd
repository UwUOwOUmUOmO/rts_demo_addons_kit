extends KinematicBody

class_name Combatant

signal __combatant_out_of_hp(combatant)

const FORE					= deg2rad(180.0)
const AFT					= -FORE
const HARD_PORT				= deg2rad(90.0)
const HARD_STARBOARD		= -HARD_PORT

#var _is_ordanance := false
var _trackable := true
var _controller = null
var _trackedBy = null
var _vehicle_config: Dictionary = {}
var _use_physics_process := true

var _heat_signature := 10.0

var hp := 100.0
var currentSpeed := 0.0

func _damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		emit_signal("__combatant_out_of_hp", self)
