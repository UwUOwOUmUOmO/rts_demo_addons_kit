extends Spatial

class_name DistanceCompensator

var target: Spatial = null setget set_target, get_target
var use_physics_process := true
var leading := 1.0
var use_advanced := true
var dead_stop_threshold := -120.0

var cleanned := false
var last_location := Vector3.ZERO
var last_velocity := 0.0
var last_direction := Vector3.ZERO
var acceleration := 0.0

func set_target(t: Spatial):
	target = t
	_clean_all()

func get_target():
	return target

func _process(delta):
	if not use_physics_process:
		_compute(delta)

func _physics_process(delta):
	if use_physics_process:
		_compute(delta)

func _clean_all() -> void:
	last_location = Vector3.ZERO
	last_velocity = 0.0
	last_direction = Vector3.ZERO
	acceleration = 0.0
	cleanned = true

# OPTIMIZE
func _compute(delta: float) -> void:
	if use_advanced:
		_advanced_leading(delta)
	else:
		_simple_leading(delta)

# Only calculate target direction
func _simple_leading(delta: float) -> void:
	if target == null:
		if not cleanned:
			_clean_all()
		return
	#--------------------------------------------
	var current_location := target.global_transform.origin
	if last_location == current_location:
		if not cleanned:
			_clean_all()
		return
	if last_location == Vector3.ZERO:
		last_location = current_location
		global_translate(last_location - global_transform.origin)
		return
	last_direction = last_location.direction_to(current_location)
	#--------------------------------------------
	if last_direction != Vector3.ZERO:
		global_translate(current_location - global_transform.origin)
		global_translate(last_direction * leading)
	last_location = current_location

# Calculate target direction, velocity and acceleration. Turn rate not included
func _advanced_leading(delta: float) -> void:
	if target == null:
		if not cleanned:
			_clean_all()
		return
	#--------------------------------------------
	var current_location := target.global_transform.origin
	if last_location == current_location:
		if not cleanned:
			_clean_all()
		return
	if last_location == Vector3.ZERO:
		last_location = current_location
		global_translate(last_location - global_transform.origin)
		return
	var direction	    := last_location.direction_to(current_location)
	var distance:  float = last_location.distance_to(current_location)
	var velocity:  float = distance / delta
	if last_velocity != 0.0:
		acceleration = (velocity - last_velocity) / delta
		if acceleration < dead_stop_threshold:
			acceleration = 0.0
	else:
		acceleration = 0.0
	var predicted_distance := 0.0
	predicted_distance  = (velocity * leading) + (0.5 * acceleration * leading)
#	predicted_distance = velocity * leading
	var predicted_direction := direction * predicted_distance
	#--------------------------------------------
	if predicted_direction != Vector3.ZERO:
		global_translate(current_location - global_transform.origin)
		global_translate(predicted_direction)
		last_direction = predicted_direction
	last_location = current_location
	last_velocity = velocity

func calculate_leading(bullet_velocity: float, initial_location: Vector3,\
		margin := 0.3, steps := 3, use_steps := true) -> float:
	var diff := 1000.0
	var deltaTime := 0.0
	var last_predicted_location := global_transform.origin
	var predicted_distance := 0.0
	var current_step := 0
	while true:
		if (abs(diff) < margin and not use_steps)\
			or (current_step >= steps and use_steps):
			break
		if deltaTime == 0.0:
			deltaTime = last_predicted_location.distance_to(initial_location)\
				/ bullet_velocity
			diff = deltaTime
		else:
			var newTime = last_predicted_location.distance_to(initial_location)\
				/ bullet_velocity
			diff = newTime - deltaTime
			deltaTime = newTime
		predicted_distance = (last_velocity * deltaTime) +\
			((1/2) * acceleration * deltaTime)
		last_predicted_location += last_direction.normalized() * predicted_distance
		current_step += 1
	return deltaTime

#static func _distance_compensate(origin: Vector3, direction: Vector3,\
#	speed: float, dtime: float) -> Vector3:
#	return origin + (direction * speed * dtime)
#
#static func _leading_method_1(target: Vector3, td: Vector3, lead: float) -> Vector3:
#	return _distance_compensate(target, td, lead, 1.0)
#
#static func _leading_method_2(hunter: Vector3, hd: Vector3, target: Vector3,\
#	td: Vector3, lead: float) -> Vector3:
#	if hd <= td:
#		return Vector3.ZERO
#	var distance1 := target - hunter
#	var time1 := distance1.length() / hd.length()
#	var compensation := _distance_compensate(target, td, lead, time1)
#	return compensation
