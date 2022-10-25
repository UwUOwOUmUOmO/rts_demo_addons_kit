extends Reference

class_name SimpleIntegratedMissilePerformer

var target: Combatant = null
var host: Combatant = null

var max_speed := 0.0
var inherited_speed := 0.0
var current_speed := 0.0

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
	current_speed = clamp(inherited_speed, 0.0, max_speed * 2.0)

func ticks(delta: float, _optional = null):
	_des = target.global_transform.origin
	# ---------------- SPEED ----------------
	var speed_change := 0.0
	if current_speed < max_speed:
		speed_change += accel * delta
	elif current_speed > max_speed:
		speed_change -= accel * delta
	speed_change += current_speed
	current_speed = min(speed_change, max_speed)
	# --------------- ROTATION ---------------
	manual_lerp_steer(host, _des, fixed_turn_rate)
	# --------------- FINALIZE ---------------
	var dir := (-host.global_transform.basis.z) * current_speed
	host.move_and_slide(dir, Vector3.UP)
