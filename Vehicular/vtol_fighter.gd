extends Combatant

class_name VTOLFighterBrain

const VTOL_DEFAULT_CONFIG = {
	"acceleration":			1.0,
	"deccelaration": 		-2.0,
	"speedSnapping":		1.0,
	"climbRate":			1.2,
	"minThrottle":			0.2,
	"maxThrottle":			1.0,
	"maxSpeed": 			100,
	"rollAmplifier":		10.0,
	"pitchAmplifier":		0.07,
	"maxRollAngle":			deg2rad(45),
	"maxPitchAngle":		deg2rad(90),
	"turnRate":				0.05,
	"maxTurnRate":			0.05,
	"slowingAt":			0.3,
	"orbitError":			0.01,
	"deadzone":				1.0,
	"slowingRange":			60.0,
}

var isReady := false
var destination := Vector3() setget _setCourse
var trackingTarget: Spatial = null setget _setTracker
var isMoving := false setget _setMoving, _getMoving
var overdriveThrottle := -1.0
var inheritedSpeed := 0.0

var startingPoint := Vector3()
var lookAtVec := Vector3()
var slowingRange := 0.0
var throttle := 0.0
var speedPercentage := 0.0
var distance := 0.0
var currentSpeed := 0.0
var previousYaw := 0.0
var currentRoll := 0.0
var targetRoll := 0.0
var allowedTurn: float = 0.05

var timer1 := 0.0

func _init():
	_vehicle_config = VTOL_DEFAULT_CONFIG.duplicate()

func _ready():
	previousYaw = global_transform.basis.get_euler().y

func _process(delta):
	timer1 += delta
	if not _use_physics_process:
		_compute(delta)

func _physics_process(delta):
	if _use_physics_process:
		_compute(delta)

func _compute(delta):
	if trackingTarget != null:
		_bakeDestination(trackingTarget.global_transform.origin)
		if not isMoving:
			_setMoving(true)
	if not isReady:
		if get_parent():
			isReady = true
	elif isMoving:
		var loaded = _prepare()
		var allowedSpeed = loaded["allowedSpeed"]
		var currentYaw = loaded["currentYaw"]
		# Calculate and enforce roll
		_enforceRoll(currentYaw)
		# Calculate speed
		_calculateSpeed(allowedSpeed)
		# Calculate elevation
		var forward = -global_transform.basis.z
		var moveDistance = -global_transform.basis.z * (currentSpeed)
		moveDistance += global_transform.basis.y\
			* (destination.y - global_transform.origin.y)\
			* _vehicle_config["climbRate"]
		move_and_slide(moveDistance, Vector3.UP)
#		global_translate(moveDistance * delta)
		previousYaw = currentYaw
	if isReady:
		_rollProcess()
		_setRoll(lerp(currentRoll, 0.0, 0.9995))

func _prepare():
	var currentYaw = global_transform.basis.get_euler().y
	distance = global_transform.origin.distance_to(destination)
	var allowedSpeed: float = _vehicle_config["maxSpeed"] * throttle
	if allowedSpeed != 0.0:
		speedPercentage = clamp(currentSpeed / allowedSpeed, 0.0, 1.0)
	else:
		speedPercentage = 0.0
	_calculateTurnRate()
	_setMovement()
	return {"allowedSpeed": allowedSpeed,\
			"currentYaw": currentYaw}

func _enforceRoll(currentYaw):
	var roll = (currentYaw - previousYaw)
	_setRoll(clamp(roll * _vehicle_config["rollAmplifier"],\
		-_vehicle_config["maxRollAngle"], _vehicle_config["maxRollAngle"]))

func _calculateSpeed(allowedSpeed):
	if currentSpeed < allowedSpeed:
		currentSpeed = clamp(currentSpeed + _vehicle_config["acceleration"],\
				0.0, allowedSpeed)
	elif currentSpeed > allowedSpeed:
		currentSpeed = clamp(currentSpeed + _vehicle_config["deccelaration"],\
				allowedSpeed, _vehicle_config["maxSpeed"])

func _calculateTurnRate():
	var minTurnRate = _vehicle_config["turnRate"]
	var maxTurnrate = _vehicle_config["maxTurnRate"]
	allowedTurn = lerp(maxTurnrate, minTurnRate, clamp(speedPercentage, 0.0, 1.0))

# TODO: clean up
func _turn(player: Vector3):
	var global_pos = global_transform.origin
	var player_pos = player
	var rotation_speed = allowedTurn
	var wtransform = global_transform.\
		looking_at(Vector3(player_pos.x,global_pos.y,player_pos.z),Vector3.UP)
	var wrotation = Quat(global_transform.basis).slerp(Quat(wtransform.basis), rotation_speed)

	global_transform = Transform(Basis(wrotation), global_transform.origin)

func _setMovement():
	if overdriveThrottle != -1.0:
		throttle = overdriveThrottle
		return
	if global_transform.origin.distance_to(destination) <= _vehicle_config["deadzone"]:
		throttle = 0.0
		_setMoving(false)
		if currentSpeed < _vehicle_config["speedSnapping"]\
				and throttle <= _vehicle_config["minThrottle"]:
			_setMoving(false)
			return
		if global_transform.origin.distance_to(destination) <= _vehicle_config["orbitError"]:
			_setMoving(false)
			global_translate(destination - global_transform.origin)
	elif slowingRange >= distance:
		throttle = clamp(distance / slowingRange, _vehicle_config["minThrottle"], 1.0)
	else:
		if throttle != 1.0:
			throttle = 1.0
	_turn(destination)

func _setRoll(r: float):
	targetRoll = r

func _rollProcess(weigh = 0.05):
	currentRoll = lerp(currentRoll, targetRoll, weigh)
	var ch = get_children()
	for c in ch:
		c.rotation.z = currentRoll

func _bakeDestination(d: Vector3):
	startingPoint = global_transform.origin
	var inv_per: float = 1.0 - _vehicle_config["slowingAt"]
	destination = d
#	slowingRange = inv_per * startingPoint.distance_to(destination)
	slowingRange = _vehicle_config["slowingRange"]
	lookAtVec = startingPoint.direction_to(destination)
	if currentSpeed == 0.0:
		currentSpeed = inheritedSpeed

func _setTracker(target: Spatial):
	if target == null:
		_setMoving(false)
		trackingTarget = target
		return
	trackingTarget = target
	if not isMoving:
		_setMoving(true)
	trackingTarget = target
	_bakeDestination(trackingTarget.global_transform.origin)

func _setCourse(des: Vector3):
	if not isMoving:
		_setMoving(true)
#	_setMoving(true)
	if trackingTarget != null:
		trackingTarget = null
	_bakeDestination(des)

func _setMoving(m: bool):
	isMoving = m
	# Reset all variable
	lookAtVec = Vector3()
	startingPoint = Vector3()
	throttle = 0.0
	speedPercentage = 0.0
	distance = 0.0
	currentSpeed = 0.0
	previousYaw = 0.0
	targetRoll = 0.0
	allowedTurn = _vehicle_config["turnRate"]

func _getMoving():
	return isMoving
