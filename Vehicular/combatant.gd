extends KinematicBody

class_name Combatant

signal __combatant_out_of_hp(combatant)

const FORE					= PI
const AFT					= -FORE
const HARD_PORT				= PI / 2.0
const HARD_STARBOARD		= -HARD_PORT

var _trackable := true
var _controller = null
var _trackedBy = null
var _ref: InRef = null
var _vehicle_config: Configuration = null
var _use_physics_process: bool = SingletonManager.fetch("UtilsSettings").use_physics_process

var _heat_signature := 10.0
var hp := 100.0
var currentSpeed := 0.0

var hardpoints := {
	"PRIMARY":		[],
	"SECONDARY":	[],
}

func _damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		emit_signal("__combatant_out_of_hp", self)

func _damage_over_time(total: float, duration: float) -> void:
	if duration <= 0.0:
		Out.print_error("Duration must be above 0", get_stack())
	var dps := total / duration
	var damage_per_turn: float = dps * \
		float(SingletonManager.static_services["UtilsSettings"].fixed_delta)
	while total > 0.0:
		total -= damage_per_turn
		_damage(damage_per_turn)
		if hp <= 0.0:
			break
		yield(get_tree(), "physics_frame")

