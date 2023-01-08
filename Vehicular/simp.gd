extends Reference

class_name SimpleIntegratedMissilePerformer

const GRAVITY_CONSTANT := 9.8

var target: Spatial = null
var host: Spatial = null
var accelarator := true
var gravity := false
var allow_turn := true

var max_climb := 0.1
var max_speed := 0.0
var inherited_speed := 0.0
var currentSpeed := 0.0

var accel := 0.0
var fixed_turn_rate := 0.0

var _des := Vector3.ZERO

static func manual_lerp_steer(host: Spatial, to: Vector3, amount: float):
	var global_pos: Vector3 = host.global_transform.origin
	# var looking_at: Vector3 = -afb.global_transform.basis.z
	if to == global_pos: return
	var wtransform: Transform = host.global_transform.\
		looking_at(Vector3(to.x,global_pos.y,to.z),Vector3.UP)
	var wrotation: Quat = host.global_transform.basis.get_rotation_quat().slerp(Quat(wtransform.basis),\
		amount)
	host.global_transform = Transform(Basis(wrotation), host.global_transform.origin)

func engage():
	currentSpeed = clamp(inherited_speed, 0.0, max_speed * 2.0)

const ELEV_IGNORE := 10.0
const DIP_ANGLE := deg2rad(20.0)
const T_LERP := 0.1
const T_BUFFER := 100.0

static func find_angular_elevation_difference(my_loc: Vector3, curr_fwd: Vector3, \
	des: Vector3, normal: Vector3, buffer: float = 0.0) -> float:
		
		var fwd := Vector3.ZERO
		var elev_diff := des.y - my_loc.y
		var dir := elev_diff / abs(elev_diff)
		if abs(elev_diff) < ELEV_IGNORE:
			fwd = (des - my_loc).normalized()
		else:
			fwd = ((des + (Vector3.DOWN * dir * buffer)) - my_loc).normalized()
		return curr_fwd.signed_angle_to(fwd, normal)

static func find_angular_elevation_difference_n(curr: Spatial, tar: Spatial) -> float:
	var bisect := GeometryMf.pe_create_2vn(curr.global_transform.origin, \
		curr.global_transform.basis.y, -curr.global_transform.basis.z,
		curr.global_transform.basis.x)
	var fixed_des_loc := GeometryMf.point_project(tar.global_transform.origin, \
		bisect)
	var fixed_curr_fwd := GeometryMf.point_project((bisect.origin + bisect.vec2), \
		bisect)
	fixed_curr_fwd = (fixed_curr_fwd - bisect.origin).normalized()
	var fixed_target_fwd := (fixed_des_loc - bisect.origin).normalized()
	return fixed_curr_fwd.signed_angle_to(fixed_target_fwd, bisect.normal)

static func resolve_elevation(host: Spatial, target: Spatial, elev_delta: float, \
	elev_ignore := ELEV_IGNORE, translation_buffer := T_BUFFER, \
	translation_lerp := T_LERP):
	var elev_diff: float = target.global_transform.origin.y \
		- host.global_transform.origin.y
	var dir := elev_diff / abs(elev_diff)
	if abs(elev_diff) < elev_ignore:
		pass
	else:
#		var curr_translation := host.global_transform.origin
#		curr_translation.y = lerp(curr_translation.y, \
#			target.global_transform.origin.y + (translation_buffer * dir), \
#			translation_lerp)
#		curr_translation.y += t_delta
#		host.global_translate(curr_translation - host.global_transform.origin)
		var t_delta: float = min(abs(elev_diff), abs(elev_delta)) * dir
		host.global_translate(Vector3(0.0, t_delta, 0.0))

func adjust_speed(delta: float):
	var speed_change := 0.0
	if currentSpeed < max_speed:
		speed_change += accel * delta
	elif currentSpeed > max_speed:
		speed_change -= accel * delta
	speed_change += currentSpeed
	currentSpeed = min(speed_change, max_speed)

func ticks(delta: float, _optional = null):
	if accelarator:
		adjust_speed(delta)
	if is_instance_valid(target) and allow_turn:
		_des = target.global_transform.origin
		manual_lerp_steer(host, _des, fixed_turn_rate)
		resolve_elevation(host, target, max_climb * delta)

#		var elevation_adjustment :=\
#			find_angular_elevation_difference(host.global_transform.origin, \
#			-target.global_transform.basis.z, _des, \
#			host.global_transform.basis.x, 100.0)
#		var t_r := fixed_turn_rate
#		var dir := elevation_adjustment / abs(elevation_adjustment)
#		elevation_adjustment = min(abs(elevation_adjustment), (t_r)) * dir
#		host.rotate_x(elevation_adjustment)

	var dir := (-host.global_transform.basis.z) * currentSpeed
	if gravity:
		dir += Vector3.DOWN * GRAVITY_CONSTANT
	host.global_translate(dir * delta)
