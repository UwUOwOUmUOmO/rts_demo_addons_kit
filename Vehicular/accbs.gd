extends Node

# AirCombatant Context Based Steering
class_name AirComCBS

const MIN_THRESHOLD := 0.0
const MAX_THRESHOLD := 0.99999

enum RAYS_MODE {
	FOUR_SURROUND,
	EIGHT_SURROUND,
	SIXTEEN_SURROUND,
	THIRTY_TWO_SURROUND,
}

# Settings
var rays_formation: int = RAYS_MODE.EIGHT_SURROUND setget set_formation
var host: AirCombatant = null setget set_host
var ray_length := 300.0
var interest_prevelent := 1.0
var danger_threshold := 0.3 setget set_threshold
var use_physics_process := true setget set_pp
var suggested_direction := Vector3.FORWARD

# Internals
var disabled := true
var ray_count := 0
var interests := PoolRealArray()
var dangers := PoolRealArray()

func _init(h: AirCombatant = null):
	set_host(h)
	set_formation(rays_formation)

func _ready():
	set_pp(use_physics_process)

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
	interests.resize(size)
	for iter in range(0, size):
		interests[iter] = 1.0
	dangers.resize(size)
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

func _physics_process(delta):
	compute(delta)

func _process(delta):
	compute(delta)

func cast(base_loc: Vector3, fwd_ray: Vector3) -> Vector3:
	var pdss := get_viewport().world.direct_space_state
	var angle_delta := TAU / float(ray_count)
	var current_ray := fwd_ray
	var final_direction := Vector3.ZERO
	for iter in range(0, ray_count):
		# Preparations
		var des_ray := base_loc + (current_ray * ray_length)
		var collided_with := pdss.intersect_ray(base_loc, des_ray, [host])
		# Danger detected
		if collided_with:
			var ray_to_collision: Vector3 = collided_with["position"] - base_loc
			var rtc_length := ray_to_collision.length()
			var danger_percentage := rtc_length / ray_length
			danger_percentage = (danger_percentage - danger_threshold) \
				/ (1.0 - danger_threshold)
			danger_percentage = 1.0 - danger_percentage
			danger_threshold = clamp(danger_threshold, 0.0, INF)
			dangers[iter] = danger_percentage
		else:
			dangers[iter] = 0.0
		# Finalize
		final_direction += current_ray * interests[iter]
		final_direction -= current_ray * dangers[iter]
		final_direction = final_direction.normalized()
		current_ray = current_ray.rotated(Vector3.UP, angle_delta)
	return final_direction

func compute(delta: float):
	if disabled:
		return
	var base_location: Vector3 = host.global_transform.origin
	var base_fwd_vec: Vector3 = -host.global_transform.basis.z
	var destination := host.current_destination
	var ideal_vector := (destination - base_location).normalized()
	ideal_vector *= interest_prevelent
	var saturated := cast(base_location, base_fwd_vec)
	suggested_direction = (saturated + ideal_vector).normalized()
