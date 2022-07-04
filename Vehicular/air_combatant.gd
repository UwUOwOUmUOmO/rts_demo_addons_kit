extends Combatant

# Virtual class, do not explicitly instance this
class_name AirCombatant

const GRAVITATIONAL_CONSTANT = 9.8

enum PROJECTILE_TYPE {
	OTHER 		= 0,
	AIRCRAFT 	= 1,
	MISSILE 	= 2,
	AAM 		= 4,
	AGM 		= 8,
}

signal __tracking_target(brain, target)
signal __loss_track_of_target(brain)
signal __destination_arrived(brain)

# Settings
var useBuiltinTranslator := true
var isReady := false
var useRudder := false
var enableGravity := false
var rudderAngle := 0.0
var destination := Vector3() setget set_course
var trackingTarget: Spatial = null setget set_tracking_target
var isMoving := false setget set_moving
var overdriveThrottle := -1.0
var inheritedSpeed := 0.0
var device: int = PROJECTILE_TYPE.AIRCRAFT

# Volatile
var rudder: Spatial = null
var throttle := 0.0
var speedPercentage := 0.0
var distance := 0.0 setget , get_distance
var distance_squared := 0.0

func _enter_tree():
	if device & PROJECTILE_TYPE.AIRCRAFT:
		add_to_group("air_combatants")
	elif device & PROJECTILE_TYPE.MISSILE:
		add_to_group("missiles")

func _exit_tree():
	if device & PROJECTILE_TYPE.AIRCRAFT:
		remove_from_group("air_combatants")
	elif device & PROJECTILE_TYPE.MISSILE:
		remove_from_group("missiles")

func _ready():
	rudder = Spatial.new()
	add_child(rudder)
	rudder.translation = Vector3(0.0, 0.0, -50.0)

func set_course(des: Vector3) -> void:
	pass

func set_tracking_target(target: Spatial) -> void:
	pass

func set_moving(m: bool) -> void:
	pass

func set_distance(_d) -> void:
	pass

func get_distance() -> float:
	return sqrt(distance_squared)
