extends Combatant

# Virtual class, do not explicitly instance this
class_name AirCombatant

const GRAVITATIONAL_CONSTANT = 9.8

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

# Volatile
var rudder: Spatial = null
var throttle := 0.0
var speedPercentage := 0.0
var distance := 0.0 setget , get_distance
var distance_squared := 0.0

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
