extends AirCombatant

class_name VTOLFighterBrain

onready var  fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta

# Volatile
var startingPoint := Vector3()
var lookAtVec := Vector3()
var slowingRange := 0.0
var slowingRange_squared := 0.0
var switchDesZone_squared := 0.0
var previousYaw := 0.0
var currentRoll := 0.0
var targetRoll := 0.0
var allowedTurn := 0.05
var speedLoss := 0.0
var realSpeedLoss := 0.0

# Special
var old_thottle_override := -1.0

func _init():
	_vehicle_config = AircraftConfiguration.new()

func _ready():
	._ready()
	previousYaw = global_transform.basis.get_euler().y
	_heat_signature = _vehicle_config.heatSignature
	set_physics_process(_use_physics_process)
	set_process(not _use_physics_process)

func _process(delta):
	._process(delta)
	if not _use_physics_process:
		_compute(delta)

func _physics_process(delta):
#	._physics_process(delta)
	if _use_physics_process:
		_compute(fixed_delta)

func _compute(delta):
	var moveDistance = Vector3.ZERO
	# if useRudder:
	# 	moveDistance = _rudderControl()
	if useRudder:
		rudderCheck()
	if false:
		return
	elif trackingTarget != null:
		if not is_instance_valid(trackingTarget):
			emit_signal("__loss_track_of_target", self)
			trackingTarget = null
		else:
			_bakeDestination(trackingTarget.global_transform.origin)
			if not isMoving:
				set_moving(true)
	if not isReady:
		if get_parent():
			isReady = true
	# elif isMoving and not useRudder:
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
		moveDistance = forward * (currentSpeed)
		moveDistance += global_transform.basis.y\
			* (current_destination.y - global_transform.origin.y)\
			* _vehicle_config.climbRate
		previousYaw = currentYaw
	if isReady:
		if enableGravity:
			moveDistance += -global_transform.basis.y\
				* (0.5 * GRAVITATIONAL_CONSTANT * _vehicle_config.weight)
		if useBuiltinTranslator:
			move_and_slide(moveDistance, Vector3.UP)
		else:
			global_translate(moveDistance * delta)
		_rollProcess()
		_setRoll(lerp(currentRoll, 0.0, 0.9995))

func rudderCheck():
	rudder.rotation = Vector3(0.0, rudderAngle, 0.0)
	set_tracking_target(rudder)

func _rudderControl() -> Vector3:
	var allowedSpeed: float =_vehicle_config.maxSpeed
	if allowedSpeed == 0.0:
		speedPercentage = 0.0
	else:
		speedPercentage = clamp(currentSpeed / allowedSpeed, 0.0, 1.0)
	if rudderAngle != 0.0:
		_calculateTurnRate()
	_calculateSpeed(allowedSpeed)
	var forward = -global_transform.basis.z
	if rudderAngle != 0.0:
		var rotated: Vector3 = forward.rotated(global_transform.basis.y, rudderAngle)
		_turn(global_transform.origin + rotated)
	return forward * currentSpeed

func _prepare():
	var currentYaw = global_transform.basis.get_euler().y
	distance_squared = global_transform.origin.distance_squared_to(current_destination)
	var accel: float = _vehicle_config.deccelaration
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
	_turn(current_destination)
	return {"allowedSpeed": allowedSpeed,\
			"currentYaw": currentYaw}

func _enforceRoll(currentYaw: float):
	var roll = (currentYaw - previousYaw)
	_setRoll(clamp(roll * _vehicle_config.rollAmplifier,\
		-_vehicle_config.maxRollAngle, _vehicle_config.maxRollAngle))

func _calculateSpeed(allowedSpeed: float):
	var speedMod := 0.0
	var clampMin := 0.0
	if currentSpeed < allowedSpeed:
		speedMod = _vehicle_config.acceleration
		clampMin = 0.0
	elif currentSpeed > allowedSpeed:
		speedMod = _vehicle_config.deccelaration
		clampMin = allowedSpeed
	realSpeedLoss = abs(_vehicle_config.deccelaration * speedLoss)
	currentSpeed = clamp(clamp(currentSpeed + speedMod,\
		clampMin, _vehicle_config.maxSpeed) - realSpeedLoss, 0.0, _vehicle_config.maxSpeed)

func _calculateTurnRate():
	var minTurnRate = _vehicle_config.turnRate
	var maxTurnrate = _vehicle_config.maxTurnRate
	allowedTurn = lerp(maxTurnrate, minTurnRate, clamp(speedPercentage, 0.0, 1.0))
	#---------------------------------------------------------------------
	var fwd_vec := -global_transform.basis.z
	var target_vec := global_transform.origin.direction_to(current_destination)
	var angle := abs(fwd_vec.angle_to(target_vec))
	var percentage: float = angle / FORE
	var aero: float = _vehicle_config.aerodynamic
	var loss_rate := 1.0 - aero
	var real_loss: float = loss_rate * percentage * allowedTurn * _vehicle_config.speedLossMod
	speedLoss = real_loss

# TODO: clean up
func _turn(to: Vector3, turningSpeed := allowedTurn):
	var global_pos = global_transform.origin
	var target_pos = to
	var rotation_speed = turningSpeed
	var wtransform = global_transform.\
		looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3.UP)
	var wrotation = Quat(global_transform.basis).slerp(Quat(wtransform.basis),\
		rotation_speed)

	global_transform = Transform(Basis(wrotation), global_transform.origin)

func _setMovement():
	var d_s: float = _vehicle_config.deadzone
	d_s *= d_s
	var o_s: float = _vehicle_config.orbitError
	o_s *= o_s
	if overdriveThrottle > 0.0:
		throttle = overdriveThrottle
		if distance_squared <= d_s * 2.0:
			chart_course()
		return
	if distance_squared <= switchDesZone_squared:
		if chart_course():
			return
	if distance_squared <= d_s:
		throttle = 0.0
		set_moving(false)
		if currentSpeed < _vehicle_config.speedSnapping\
				and throttle <= _vehicle_config.minThrottle:
			set_moving(false)
			return
		if distance_squared <= o_s:
			set_moving(false)
		if currentSpeed < _vehicle_config.speedSnapping\
				and throttle <= _vehicle_config.minThrottle:
			# set_moving(false)
			# return
			pass
		elif distance_squared <= o_s:
			# set_moving(false)
			global_translate(current_destination - global_transform.origin)
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
	current_destination = d
	lookAtVec = startingPoint.direction_to(current_destination)
	distance_squared = global_transform.origin.distance_squared_to(current_destination)
	var sdzp: float= _vehicle_config.switchDesZonePerc
	sdzp *= sdzp
	switchDesZone_squared = clamp(distance_squared * sdzp, \
		_vehicle_config.minSDZS, _vehicle_config.maxSDZS)
	if currentSpeed == 0.0:
		currentSpeed = clamp(inheritedSpeed, 0.0, _vehicle_config.maxSpeed)
		inheritedSpeed = 0.0

func set_tracking_target(target: Spatial):
	if target == null:
		set_moving(false)
		trackingTarget = target
		return
	trackingTarget = target
	if not isMoving:
		set_moving(true)
	trackingTarget = target
	_bakeDestination(trackingTarget.global_transform.origin)
	emit_signal("__tracking_target", self, target)

func chart_course() -> bool:
	if destinations_list.empty():
		overdriveThrottle = old_thottle_override
		return false
	var next_des := destinations_list[0]
	_dl_mutex.lock()
	destinations_list.remove(0)
	_dl_mutex.unlock()
	set_course(next_des)
	return true

func set_course(des: Vector3):
	if trackingTarget != null:
		trackingTarget = null
	if not isMoving:
		set_moving(true)
	_bakeDestination(des)
#	set_moving(true)

func set_multides(des: PoolVector3Array) -> void:
	destinations_list = des
	# old_thottle_override = overdriveThrottle
	# overdriveThrottle = 1.0
	if not chart_course():
		set_moving(false)

func set_moving(m: bool):
	if not m:
		emit_signal("__destination_arrived", self)
	else:
		emit_signal("__started_moving", self)
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
