extends Combatant

class_name VTOLFighterBrain

const OLD_VTOL_DEFAULT_CONFIG	= {
	"acceleration":			1.0,
	"deccelaration": 		-2.0,
	"speedSnapping":		1.0,
	"climbRate":			1.2,
	"minThrottle":			0.2,
	"maxThrottle":			1.0,
	"maxSpeed": 			100,
	"rollAmplifier":		10.0,
	"pitchAmplifier":		0.07,
	"maxRollAngle":			PI / 4.0,
	"maxPitchAngle":		PI / 2.0,
	"turnRate":				0.05,
	"maxTurnRate":			0.05,
	"slowingAt":			0.3,
	"orbitError":			0.01,
	"deadzone":				1.0,
	"slowingTime":			0.07,
	"aerodynamic":			0.8,
	"radarSignature":		1.5,
}

var isReady := false
var useRudder := false
var rudderAngle := 0.0
var destination := Vector3() setget _setCourse
var trackingTarget: Spatial = null setget _setTracker
var isMoving := false setget _setMoving, _getMoving
var overdriveThrottle := -1.0
var inheritedSpeed := 0.0

var startingPoint := Vector3()
var lookAtVec := Vector3()
var slowingRange := 0.0
var slowingRange_squared := 0.0
var throttle := 0.0
var speedPercentage := 0.0
var distance := 0.0 setget , get_distance
var distance_squared := 0.0
var previousYaw := 0.0
var currentRoll := 0.0
var targetRoll := 0.0
var allowedTurn := 0.05
var speedLoss := 0.0
var realSpeedLoss := 0.0

func get_distance():
	return sqrt(distance_squared)

func _init():
	_vehicle_config = VTOLConfiguration.new()

func _ready():
	previousYaw = global_transform.basis.get_euler().y

func _process(delta):
	if not _use_physics_process:
		_compute(delta)

func _physics_process(delta):
	if _use_physics_process:
		_compute(delta)

func _compute(delta):
	if useRudder:
		_rudderControl()
	elif trackingTarget != null:
		_bakeDestination(trackingTarget.global_transform.origin)
		if not isMoving:
			_setMoving(true)
	if not isReady:
		if get_parent():
			isReady = true
	elif isMoving and not useRudder:
		var loaded = _prepare()
		var allowedSpeed = loaded["allowedSpeed"]
		var currentYaw = loaded["currentYaw"]
		# Calculate and enforce roll
		_enforceRoll(currentYaw)
		# Calculate speed
		_calculateSpeed(allowedSpeed)
		# Calculate elevation
		var forward = -global_transform.basis.z
		var moveDistance = forward * (currentSpeed)
		moveDistance += global_transform.basis.y\
			* (destination.y - global_transform.origin.y)\
			* _vehicle_config.climbRate
		move_and_slide(moveDistance, Vector3.UP)
		previousYaw = currentYaw
	if isReady:
		_rollProcess()
		_setRoll(lerp(currentRoll, 0.0, 0.9995))

func _rudderControl():
	var allowedSpeed: float =_vehicle_config.maxSpeed
	speedPercentage = clamp(currentSpeed / allowedSpeed, 0.0, 1.0)
	if rudderAngle != 0.0:
		_calculateTurnRate()
	_calculateSpeed(allowedSpeed)
	var forward = -global_transform.basis.z
	if rudderAngle != 0.0:
		var rotated: Vector3 = forward.rotated(global_transform.basis.y, rudderAngle)
		_turn(global_transform.origin + rotated)
	move_and_slide(forward * currentSpeed, Vector3.UP)

func _prepare():
	var currentYaw = global_transform.basis.get_euler().y
	distance_squared = global_transform.origin.distance_squared_to(destination)
	var accel: float = _vehicle_config.deccelaration
#	var slowingTime: float = abs(currentSpeed / accel)
	var slowingTime: float = _vehicle_config.slowingTime
	slowingRange = (currentSpeed * slowingTime) + (0.5 * accel * slowingTime)
	slowingRange_squared = slowingRange * slowingRange
	var allowedSpeed: float = _vehicle_config.maxSpeed * throttle
	if allowedSpeed != 0.0:
		speedPercentage = clamp(currentSpeed / allowedSpeed, 0.0, 1.0)
	else:
		speedPercentage = 0.0
	_calculateTurnRate()
	_setMovement()
	_turn(destination)
	return {"allowedSpeed": allowedSpeed,\
			"currentYaw": currentYaw}

func _enforceRoll(currentYaw):
	var roll = (currentYaw - previousYaw)
	_setRoll(clamp(roll * _vehicle_config.rollAmplifier,\
		-_vehicle_config.maxRollAngle, _vehicle_config.maxRollAngle))

func _calculateSpeed(allowedSpeed):
	var speedMod := 0.0
	var clampMin := 0.0
	if currentSpeed < allowedSpeed:
		speedMod = _vehicle_config.acceleration
		clampMin = 0.0
	elif currentSpeed > allowedSpeed:
		speedMod = _vehicle_config.deccelaration
		clampMin = allowedSpeed
	realSpeedLoss = abs(_vehicle_config.deccelaration * speedLoss)
	currentSpeed = clamp(currentSpeed + speedMod,\
		clampMin, _vehicle_config.maxSpeed) - realSpeedLoss

func _calculateTurnRate():
	var minTurnRate = _vehicle_config.turnRate
	var maxTurnrate = _vehicle_config.maxTurnRate
	allowedTurn = lerp(maxTurnrate, minTurnRate, clamp(speedPercentage, 0.0, 1.0))
	#---------------------------------------------------------------------
	var fwd_vec := -global_transform.basis.z
	var target_vec := global_transform.origin.direction_to(destination)
	var angle := abs(fwd_vec.angle_to(target_vec))
	var percentage: float = angle / FORE
	var aero: float = _vehicle_config.aerodynamic
	var loss_rate := 1.0 - aero
	var real_loss := loss_rate * percentage
	speedLoss = real_loss

# TODO: clean up
func _turn(to: Vector3, turningSpeed := allowedTurn):
	var global_pos = global_transform.origin
	var target_pos = to
	var rotation_speed = turningSpeed
	var wtransform = global_transform.\
		looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3.UP)
	var wrotation = Quat(global_transform.basis).slerp(Quat(wtransform.basis), rotation_speed)

	global_transform = Transform(Basis(wrotation), global_transform.origin)

func _setMovement():
	var d_s: float = _vehicle_config.deadzone
	d_s *= d_s
	var o_s: float = _vehicle_config.orbitError
	o_s *= o_s
	if overdriveThrottle != -1.0:
		throttle = overdriveThrottle
		return
	if distance_squared <= d_s:
		throttle = 0.0
		_setMoving(false)
		if currentSpeed < _vehicle_config.speedSnapping\
				and throttle <= _vehicle_config.minThrottle:
			_setMoving(false)
			return
		if distance_squared <= o_s:
			_setMoving(false)
			global_translate(destination - global_transform.origin)
	elif slowingRange_squared >= distance_squared:
		throttle = 0.0
	else:
		if throttle != 1.0:
			throttle = 1.0

func _setRoll(r: float):
	targetRoll = r

func _rollProcess(weigh = 0.05):
	currentRoll = lerp(currentRoll, targetRoll, weigh)
	var ch = get_children()
	for c in ch:
		c.rotation.z = currentRoll

func _bakeDestination(d: Vector3):
	useRudder = false
	startingPoint = global_transform.origin
	var inv_per: float = 1.0 - _vehicle_config.slowingAt
	destination = d
	lookAtVec = startingPoint.direction_to(destination)
	if currentSpeed == 0.0:
		currentSpeed = clamp(inheritedSpeed, 0.0, _vehicle_config.maxSpeed)
		inheritedSpeed = 0.0

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
	if trackingTarget != null:
		trackingTarget = null
	_bakeDestination(des)
	if not isMoving:
		_setMoving(true)
#	_setMoving(true)

func _setMoving(m: bool):
	isMoving = m
	# Reset all variable
	lookAtVec = Vector3()
	startingPoint = Vector3()
	throttle = 0.0
	speedPercentage = 0.0
	distance = 0.0
	distance_squared = 0.0
	currentSpeed = 0.0
	previousYaw = 0.0
	targetRoll = 0.0
	allowedTurn = _vehicle_config.turnRate

func _getMoving():
	return isMoving
