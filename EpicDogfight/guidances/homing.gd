extends WeaponGuidance

class_name HomingGuidance

var vtol: VTOLFighterBrain = null
var target: Combatant = null

var vtol_profile := VTOLFighterBrain.VTOL_DEFAULT_CONFIG
var active_range := 100.0 setget set_range, get_range
var active_range_squared := 10000.0
var detonation_distance := 1.0 setget set_ddistance, get_ddistance
var detonation_distance_squared := 1.0
var self_destruct_time := 5.0
var self_destruct_clock := 0.0
var guided := false

func set_profile(p: Dictionary):
	vtol_profile = p
	_velocity = p["maxSpeed"]

func get_profile(p: Dictionary):
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
	if guided:
		if vtol.trackingTarget != target:
			vtol._setTracker(target)
		self_destruct_clock = 0.0
		return
	var distance_squared := vtol.global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	if distance_squared < detonation_distance_squared:
		_finalize()
		_clean()
		return
	elif distance_squared <= active_range_squared:
		if vtol.trackingTarget != target:
			vtol._setTracker(target)
		self_destruct_clock = 0.0
	else:
		vtol._setCourse(vtol.global_transform.origin + (vtol.lookAtVec * _velocity * 1.5))
		if self_destruct_clock + delta > self_destruct_time:
			_finalize()
			_clean()
			return
		else:
			self_destruct_clock += delta

func _clean():
	vtol.remove_child(_projectile)
	var vp := vtol.get_parent()
	if vp:
		vp.remove_child(vtol)
	vtol.free()
	_projectile.free()
	queue_free()

func _start(move := false):
	_velocity = vtol_profile["maxSpeed"]
	_green_light = true
	vtol = VTOLFighterBrain.new()
	vtol._vehicle_config = vtol_profile
	var scene := get_tree().get_current_scene()
	if scene:
		scene.add_child(vtol)
	else:
		printerr("Error: scene not ready")
		printerr(get_stack())
		return
	while vtol.get_parent() == null:
		yield(get_tree(), "idle_frame")
	vtol.global_translate(_barrel - vtol.global_transform.origin)
	vtol.look_at(_direction, Vector3.UP)
	_projectile = _projectile_scene.instance()
	vtol.add_child(_projectile)
	_projectile.translation = Vector3.ZERO
