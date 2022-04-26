extends Combatant

class_name NGADFighterBrain

# Strategic variables
var destination := Vector3() setget _set_course
var trackingTarget: Spatial = null setget _set_tracker
var isMoving := false
var overdriveThrottle := -1.0
var distanceCalculated := false
var currentSpeed := 0.0

# Temporal variables
var startingPoint := Vector3()
var lookAtVec := Vector3()
var slowingRange := 0.0
var throttle := 0.0
var throttlePercentage := 0.0
var distance := 0.0 setget , _get_distance
var deltaRotation := Vector3.ZERO
var targetRotation := Vector3.ZERO
var originalRotation := Vector3.ZERO
var isRotating := false

# Interchangable variables
var timer1 := 0.0
var timerReset1 := -1.0
var scheduled_distance_check := false
var fwd_vec := Vector3.ZERO

func _ready():
	_vehicle_config = {
		"acceleration":			2.0,
		"deccelaration": 		-2.0,
		"minThrottle":			0.2,
		"maxThrottle":			1.0,
		"maxSpeed": 			100,
		"distanceChecking":		1.5,
		"rotationSpeed":		5.0,
		"marginError":			deg2rad(5.0),
		"deadzone":				10.0,
		"deaccelAt":			0.4,
	}

func _process(delta):
	timer1 += delta
	if timerReset1 != -1.0:
		if timer1 >= timerReset1:
			timer1 = 0.0
			timerReset1 = -1.0
			scheduled_distance_check = true
	if not _use_physics_process:
		_compute(delta)

func _physics_process(delta):
	if _use_physics_process:
		_compute(delta)

func _compute(delta: float) -> void:
	_early_schedule()
	if isMoving:
		var calculated = _calculate_prequisites()
		_enforce_throttle()
		_enforce_speed(calculated[1])
		_enforce_movement()
	_enforce_scheduled(delta)

func _calculate_prequisites() -> Array:
	var re := []
	var allowedSpeed: float = throttle * _vehicle_config["maxSpeed"]
	throttlePercentage = allowedSpeed / _vehicle_config["maxSpeed"]
	re.append(global_transform.basis.get_euler())
	re.append(allowedSpeed)
	return re

func _get_distance(forced := false) -> float:
	if distanceCalculated and not forced:
		return distance
	else:
		distance = global_transform.origin.distance_to(destination)
		distanceCalculated = true
		return distance

func _early_schedule() -> void:
	fwd_vec = -global_transform.basis.z
	if scheduled_distance_check:
		_get_distance()

func _enforce_scheduled(delta: float) -> void:
	distanceCalculated = false
	_rotation_damping(delta)

func _enforce_throttle() -> void:
	if overdriveThrottle != -1.0:
		throttle = overdriveThrottle
		return
	if not isMoving:
		throttle = 0.0
	if scheduled_distance_check:
		if _get_distance() <= _vehicle_config["deadzone"]:
			throttle = 0.0
	else:
		throttle = _vehicle_config["maxThrottle"]

func _enforce_rotation(rot: Vector3) -> void:
	var origin := global_transform.origin
	var basis := global_transform.basis
	var euler := basis.get_euler()
	var current_rot := basis.get_euler()
	if fwd_vec.angle_to(lookAtVec) < _vehicle_config["marginError"]:
		var xy_plane := GeometryMf.pe_create_2vn(origin,\
			basis.x, basis.y, fwd_vec)
		var yz_plane := GeometryMf.pe_create_2vn(origin,\
			-fwd_vec, basis.y, basis.x)
		var xz_plane := GeometryMf.pe_create_2vn(origin,\
			basis.x, -fwd_vec, basis.y)
		var target_intersect_xy := GeometryMf.point_project(destination, xy_plane)
		var target_intersect_yz := GeometryMf.point_project(destination, yz_plane)
		var delta_roll := 0.0
		var delta_pitch := target_intersect_yz.angle_to(fwd_vec)
		if yz_plane.solve(target_intersect_xy) > 0.0:
			delta_roll = - delta_roll
		if abs(delta_roll) <= (_vehicle_config["marginError"] / 2.0):
			delta_pitch = target_intersect_xy.angle_to(basis.y)
			if xz_plane.solve(target_intersect_xy) < 0.0:
				delta_pitch = -delta_pitch
		_set_rotation(Vector3(delta_pitch, 0.0, delta_roll))

func _enforce_speed(allowedSpeed: float) -> void:
	if currentSpeed < allowedSpeed:
		currentSpeed = clamp(currentSpeed + _vehicle_config["acceleration"],\
				0.0, allowedSpeed)
	elif currentSpeed > allowedSpeed:
		currentSpeed = clamp(currentSpeed + _vehicle_config["deccelaration"],\
				allowedSpeed, _vehicle_config["maxSpeed"])

func _enforce_movement() -> void:
	fwd_vec = -global_transform.basis.z
	var velocity := fwd_vec * currentSpeed
	move_and_slide(velocity, Vector3.UP)

func _inverse_rotation(rot: Vector3):
	var re := Vector3.ZERO
	re = rot
	re.z = rot.y
	return re

func _rotation_damping(delta: float) -> void:
	if isRotating and\
		abs(fwd_vec.angle_to(deltaRotation)) > _vehicle_config["marginError"]:
		rotation += deltaRotation * delta * _vehicle_config["rotationSpeed"]
		deltaRotation = Vector3.ZERO
	else:
		isRotating = false

# ------------------------------------------------------------------------------

func get_time(v: float, v0: float, a: float) -> float:
	if a != 0.0:
		return (v - v0) / a
	else:
		return 0.0

func get_distance(v: float, v0: float, a: float) -> float:
	if a != 0.0:
		return ((v * v) - (v0 * v0)) / (2 * a)
	else:
		return 0.0

# ------------------------------------------------------------------------------

func _set_rotation(rot: Vector3):
	if not isRotating:
		deltaRotation = rot
		isRotating = true
		originalRotation = global_transform.basis.get_euler()
		targetRotation = originalRotation + rot

func _bake_destination(des: Vector3, bake_timer := true) -> void:
	destination = des
	lookAtVec = (destination - startingPoint).normalized()
	if bake_timer:
		scheduled_distance_check = false
		var ac_time = get_time(_vehicle_config["maxSpeed"]\
			, 0.0, _vehicle_config["acceleration"])
		var ac_dis = get_distance(_vehicle_config["maxSpeed"]\
			, 0.0, _vehicle_config["acceleration"])
		var da_time = get_time(0.0\
			, _vehicle_config["maxSpeed"], _vehicle_config["deccelaration"])
		var da_dis = get_distance(0.0\
			, _vehicle_config["maxSpeed"], _vehicle_config["deccelaration"])
		var mid: float = distance - da_dis - ac_dis
		var mid_time: float = mid / _vehicle_config["maxSpeed"]
		timer1 = 0.0
		timerReset1 = (ac_time + mid_time + da_time)\
			- _vehicle_config["distanceChecking"]

func _set_course(des: Vector3) -> void:
	if not isMoving:
		_reset_temporal_values()
	startingPoint = global_transform.origin
	_get_distance()
	slowingRange = distance * _vehicle_config["deaccelAt"]
	_bake_destination(des)
	

func _set_tracker(target: Spatial) -> void:
	pass

func _reset_temporal_values() -> void:
	startingPoint = Vector3()
	lookAtVec = Vector3()
	slowingRange = 0.0
	throttle = 0.0
	throttlePercentage = 0.0
	distance = 0.0
	deltaRotation = Vector3.ZERO
	targetRotation = Vector3.ZERO
	originalRotation = global_transform.basis.get_euler()
	isRotating = false
