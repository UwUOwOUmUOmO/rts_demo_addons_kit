extends Spatial

class_name DistanceCompensatorV2

var target: Spatial = null setget set_target, get_target
var use_physics_process := true

var barrel: Spatial = null
var projectile_speed := 0.0
var target_speed_insure := 0.0 # FOR TEST PURPOSE ONLY

var compensation := 0.0

func set_target(t: Spatial):
	target = t
	if not target is Combatant:
		push_error("Warning: using non-Combatant node for Distance Compensator")
		print_stack()

func get_target():
	return target

func _process(delta):
	if not use_physics_process:
		_compute(delta)

func _physics_process(delta):
	if use_physics_process:
		_compute(delta)

func _compute(_delta: float) -> void:
	if target == null or barrel == null or projectile_speed <= 0.0:
		return
	var target_speed: float
	if target is Combatant:
		target_speed = target.currentSpeed
	else:
		# FOR TESTING ONLY
		target_speed = target_speed_insure
	var target_velocity: Vector3 = -target.global_transform.basis.z
	target_velocity *= target_speed
	var target_loc := target.global_transform.origin
	var barrel_loc := barrel.global_transform.origin
	var a := projectile_speed * projectile_speed - target_velocity.dot(target_velocity)
	if a == 0.0:
		return
	var b := -2 * target_velocity.dot(target_loc - barrel_loc)
	var c := -(target_loc - barrel_loc).dot(target_loc - barrel_loc)
	var delta_time := abs((b + sqrt((b * b) - (4.0 * a * c))) / (2.0 * a))
	compensation = delta_time
	var designated_loc := target_loc + (delta_time * target_velocity)
	global_translate(designated_loc - global_transform.origin)
