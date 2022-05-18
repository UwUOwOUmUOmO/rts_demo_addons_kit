extends WeaponGuidance

class_name HomingGuidance

var vtol: VTOLFighterBrain = null
var target: Spatial = null

var vtol_profile := VTOLFighterBrain.VTOL_DEFAULT_CONFIG setget set_profile, get_profile
var active_range := 100.0 setget set_range, get_range
var active_range_squared := 10000.0
var detonation_distance := 1.0 setget set_ddistance, get_ddistance
var detonation_distance_squared := 1.0
var inherited_speed := 0.0
var self_destruct_time := 5.0
var self_destruct_clock := 0.0
var guided := false setget _set_guided, _get_guided

var manual_control := false

func _set_guided(g: bool):
	guided = g

func _get_guided():
	return guided

func set_profile(p: Dictionary):
	vtol_profile = p
	_velocity = p["maxSpeed"]

func get_profile():
	return vtol_profile

func set_range(r: float):
	active_range = r
	active_range_squared = r * r

func get_range():
	return active_range

func set_ddistance(d: float):
	detonation_distance = d
	detonation_distance_squared = d * d

func get_ddistance():
	return detonation_distance

func _guide(delta: float):
	var distance_squared := vtol.global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	if guided:
		manual_control = false
		if vtol.trackingTarget != target:
			vtol._setTracker(target)
#		self_destruct_clock = 0.0
		return
	elif distance_squared < detonation_distance_squared:
		_finalize()
		return
	elif distance_squared <= active_range_squared:
		manual_control = false
		if vtol.trackingTarget != target:
			vtol._setTracker(target)
#		self_destruct_clock = 0.0
	else:
		dumb_control()
	self_destruct_handler(delta)

func dumb_control():
	if not manual_control:
		manual_control = true
		var d: float = (_velocity * self_destruct_time)\
			+ (0.5 * vtol_profile["acceleration"] * self_destruct_time)
		vtol._setCourse((vtol.global_transform.origin - vtol.global_transform.basis.z) * d)

func self_destruct_handler(delta: float):
	if self_destruct_clock + delta > self_destruct_time:
		_finalize()
		return
	else:
		self_destruct_clock += delta

func _clean():
#	if not vtol:
#		return
#	var v_parent := vtol.get_parent()
#	if v_parent:
#		v_parent.remove_child(vtol)
	vtol.queue_free()
	queue_free()

func _start(move := true):
	_velocity = vtol_profile["maxSpeed"]
	vtol = VTOLFighterBrain.new()
	vtol._vehicle_config = vtol_profile
	var scene := get_tree().get_current_scene()
	if scene:
		scene.call_deferred("add_child", vtol)
	else:
		printerr("Error: scene not ready")
		printerr(get_stack())
		return
	while vtol.get_parent() == null:
		yield(get_tree(), "idle_frame")
	vtol.global_translate(_barrel - vtol.global_transform.origin)
#	vtol.look_at(_direction, Vector3.UP)
	vtol.inheritedSpeed = inherited_speed
	vtol.overdriveThrottle = 1.0
	vtol.look_at(vtol.translation + _direction, Vector3.UP)
	_projectile = _projectile_scene.instance()
	vtol.add_child(_projectile)
	_projectile.translation = Vector3.ZERO
	_signals_init()
	_initialize()
	_green_light = true
	_boot_subsys()
