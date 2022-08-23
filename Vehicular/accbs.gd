extends Node

# AirCombatant Context Based Steering
class_name AirComCBS

const MIN_THRESHOLD := 0.0
const MAX_THRESHOLD := 0.99999
const LENGTH_THRESHOLD := pow(0.12, 2.0)
const ONE_SIXTH_PI := deg2rad(30.0)
const INTERVAL := 0.05

enum RAYS_MODE {
	FOUR_SURROUND,
	EIGHT_SURROUND,
	SIXTEEN_SURROUND,
	THIRTY_TWO_SURROUND,
}

# Settings
var collision_mask := 8
var rays_formation: int = RAYS_MODE.THIRTY_TWO_SURROUND setget set_formation
var host: AirCombatant = null setget set_host
var ray_length := 300.0
var interest_prevelent := 1.0
var danger_threshold := 0.2 setget set_threshold
var use_physics_process := true setget set_pp
var suggested_direction := Vector3.FORWARD
var raw_sensor_data := Vector3.ZERO

# Internals
var min_ray_delta := INF
var disabled := true
var ray_count := 0
var interests := PoolRealArray()
var dangers := PoolRealArray()

func _init(h: AirCombatant = null):
	set_host(h)
	set_formation(rays_formation)

func _ready():
#	set_pp(use_physics_process)
	interval_machine()

func interval_machine():
	while not is_queued_for_deletion() and is_instance_valid(host) \
		and not disabled:
			yield(Out.timer(INTERVAL), "timeout")
			compute(INTERVAL)

func set_formation(f: int):
	var size := 0
	match f:
		RAYS_MODE.FOUR_SURROUND:
			size = 4
		RAYS_MODE.EIGHT_SURROUND:
			size = 8
		RAYS_MODE.SIXTEEN_SURROUND:
			size = 16
		RAYS_MODE.THIRTY_TWO_SURROUND:
			size = 32
	dangers.resize(size)
	interests.resize(size)
	ray_count = size
	if size != 0:
		rays_formation = f

func set_threshold(t: float):
	danger_threshold = clamp(t, MIN_THRESHOLD, MAX_THRESHOLD)

func set_pp(pp: bool):
	use_physics_process = pp
	set_physics_process(pp)
	set_process(not pp)

func set_host(h: AirCombatant):
	if is_instance_valid(h):
		host = h
		disabled = false
	else:
		host = null
		disabled = true

func cast(base_loc: Vector3, fwd_ray: Vector3, to: Vector3) -> Vector3:
	var pdss := get_viewport().world.direct_space_state
	var angle_delta := TAU / float(ray_count)
	var current_ray := fwd_ray
	var final_direction := Vector3.ZERO
	var avg_ray_length := 0.0
	for iter in range(0, ray_count):
		# Preparations
		var des_ray := base_loc + (current_ray * ray_length)
		var collided_with := pdss.intersect_ray(base_loc, des_ray, \
			[host], collision_mask)
		# Danger detected
		if collided_with:
			var ray_to_collision: Vector3 = collided_with["position"] - base_loc
			var rtc_length := ray_to_collision.length()
			var danger_percentage := rtc_length / ray_length
			danger_percentage = (danger_percentage - danger_threshold) \
				/ (1.0 - danger_threshold)
			danger_percentage = 1.0 - danger_percentage
			danger_percentage = clamp(danger_percentage, 0.0, 1.0)
			dangers[iter] = danger_percentage
		else:
			dangers[iter] = 0.0
		# Finalize
		interests[iter] = clamp(current_ray.dot(to), 0.0, 1.0) + 1.0
		var ray_delta := (current_ray * interests[iter]) \
			- current_ray * dangers[iter]
		avg_ray_length += ray_delta.length()
		final_direction += ray_delta
		current_ray = fwd_ray.rotated(Vector3.UP, \
			(float(iter) * TAU) / float(ray_count))
	return final_direction

func add_front_offset(fwd_ray: Vector3, weight := 1.0) -> Vector3:
	var final := fwd_ray * weight
	final += fwd_ray.rotated(Vector3.UP, -ONE_SIXTH_PI) * weight
	final += fwd_ray.rotated(Vector3.UP,  ONE_SIXTH_PI) * weight
	return final

func compute(delta: float):
	if disabled:
		return
	if host.isMoving:
		pass
	ray_length = host.currentSpeed * 0.6
	var base_location: Vector3 = host.global_transform.origin
	var base_fwd_vec: Vector3 = -host.global_transform.basis.z
	var destination := host.current_destination
	var ideal_vector := (destination - base_location).normalized()
	ideal_vector *= interest_prevelent
	raw_sensor_data = cast(base_location, base_fwd_vec, ideal_vector)
	suggested_direction = raw_sensor_data.normalized()
