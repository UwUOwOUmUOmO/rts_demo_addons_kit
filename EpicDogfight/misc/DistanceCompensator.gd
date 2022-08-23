extends Spatial

class_name DistanceCompensator

const USE_LEAD_METHOD := 2

var target: Spatial = null setget set_target, get_target
var use_physics_process := false
var speedometer_interval := 0.05
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

func _ready():
	interval_machine()

func interval_machine():
	while not is_queued_for_deletion():
		yield(Out.timer(speedometer_interval), "timeout")
		_compute(speedometer_interval)

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
	var direction		:= last_location.direction_to(current_location)
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
	if USE_LEAD_METHOD == 2:
		return lead_method2(bullet_velocity, initial_location, margin, steps, use_steps)
	else:
		return lead_method1(bullet_velocity, initial_location, margin, steps, use_steps)

func lead_method1(bullet_velocity: float, initial_location: Vector3,\
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

func lead_method2(bullet_velocity: float, initial_location: Vector3,\
		margin := 0.3, steps := 3, use_steps := true) -> float:
	var target_velocity: Vector3 = last_direction * last_velocity
	var a: float		= bullet_velocity * bullet_velocity  - target_velocity.dot(target_velocity)
	var b: float		= -2 * target_velocity.dot(last_location - initial_location)
	var c: float		= -(last_location - initial_location).dot(last_location - initial_location)
	var delta_time		:= abs((b + sqrt((b * b) - (4.0 * a * c))) / (2.0 * a))
	return delta_time
