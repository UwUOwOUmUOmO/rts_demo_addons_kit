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
	SAM			= 16,
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

func ref_handler():
	var g: PoolStringArray = []
	if device & PROJECTILE_TYPE.AIRCRAFT:
		g.push_back("air_combatants")
	elif device & PROJECTILE_TYPE.MISSILE:
		g.push_back("missiles")
		if device & PROJECTILE_TYPE.AAM:
			g.push_back("aam_missiles")
		elif device & PROJECTILE_TYPE.AGM:
			g.push_back("agm_missiles")
		elif device & PROJECTILE_TYPE.SAM:
			g.push_back("sam_missiles")
	IRM.add(_ref, g)

func _enter_tree():
	_ref = InRef.new(self)

func _exit_tree():
	_ref.cut_tie()
	_ref = null

func _ready():
	ref_handler()
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
	if distance_squared == null:
		return 0.0
	return sqrt(distance_squared)
