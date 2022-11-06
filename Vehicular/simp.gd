extends Reference

class_name SimpleIntegratedMissilePerformer

const GRAVITY_CONSTANT := 9.8

var target: Spatial = null
var host: Spatial = null
var accelarator := true
var gravity := false
var allow_turn := true

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

	var dir := (-host.global_transform.basis.z) * currentSpeed
	if gravity:
		dir += Vector3.DOWN * GRAVITY_CONSTANT
	host.global_translate(dir * delta)
