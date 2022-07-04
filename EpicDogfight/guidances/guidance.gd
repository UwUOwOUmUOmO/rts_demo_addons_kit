extends Spatial

class_name WeaponGuidance

signal __armament_fired(guidance)
signal __armmament_armed(guidance)
signal __armament_detonated(guidance)

var _weapon_base_config: WeaponConfiguration = null

var _velocity := 0.0
var _barrel := Vector3.ZERO
var _direction := Vector3.ZERO
var _use_physics_process: bool = SingletonManager.fetch("UtilsSettings") \
	.use_physics_process
var _projectile_scene: PackedScene = null
var _projectile: Spatial = null
var _computer: FlightComputer = null
var _instrument: AirInstrument = null
var _damage_zone: Area = null
var _green_light := false
var _arm_time := 0.3
var _armed := false

func _process(delta):
	_computer_handler(delta)
	if not _use_physics_process and _green_light:
		_guide(delta)

func _physics_process(delta):
	_computer_handler(delta, true)
	if _use_physics_process and _green_light:
		var fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta
		_guide(fixed_delta)

func _computer_handler(delta: float, pp := false):
	if is_instance_valid(_computer):
		if (pp and _computer.use_physics_process) or \
		   (not pp and not _computer.use_physics_process):
				_computer._compute(delta)

	if is_instance_valid(_instrument):
		if (pp and _instrument.use_physics_process) or \
		   (not pp and not _instrument.use_physics_process):
				_instrument._compute(delta)

func _guide(delta: float):
	pass

func _start(move := true):
	if move:
		global_translate(_barrel - global_transform.origin)
	look_at(_direction, Vector3.UP)
	_projectile = _projectile_scene.instance()
	add_child(_projectile)
	_projectile.translation = Vector3.ZERO
	_projectile.look_at(global_transform.origin + _direction, Vector3.UP)
	_signals_init()
	_initialize()
	_armed = true
	_green_light = true
	_boot_subsys()

func _signals_init():
	if _projectile.has_method("arm_launched"):
		connect("__armament_fired", _projectile, "arm_launched")
	if _projectile.has_method("arm_arrived"):
		connect("__armament_detonated", _projectile, "arm_arrived")

func _boot_subsys():
	if is_instance_valid(_computer) and not _computer.enforcer_assigned:
		_computer.enforcer_assigned = true
		_computer.host = self
		if not _computer.coprocess:
			_green_light = false
		_computer._boot()
	else:
		_computer = null
	if is_instance_valid(_instrument) and not _instrument.enforcer_assigned:
		_instrument.enforcer_assigned = true
		_instrument.host = self
		if not _instrument.coprocess:
			_green_light = false
		_instrument._boot()
	else:
		_instrument = null

func _initialize():
	emit_signal("__armament_fired", self)

func _finalize():
	_green_light = false
	emit_signal("__armament_detonated", self)
	_damage_call()
	_clean()

func dmg_zone_area_max_distance() -> float:
	var collision_shape: CollisionShape = _damage_zone.get_child(0)
	var shape := collision_shape.shape
	if shape is SphereShape:
		return shape.radius
	elif shape is CapsuleShape:
		return max(shape.radius, shape.height)
	return 0.0

func dmg_cal_linear(distance: float, percent := 0.0) -> float:
	var max_dis := dmg_zone_area_max_distance()
	return (_weapon_base_config.baseDamage * percent)

func _damage_calculate(distance: float, dmg_curve: Curve = null) \
	-> float:
		var max_dis := dmg_zone_area_max_distance()
		var percent: float
		if max_dis == 0.0:
			percent = 0.0
		else:
			percent = distance / max_dis
		if dmg_curve == null:
			return dmg_cal_linear(distance, percent)
		var interp := dmg_curve.interpolate(percent)
		if dmg_curve.max_value == 1.0:
			return (_weapon_base_config.baseDamage * interp)
		return interp

func _damage_call():
	if not is_instance_valid(_damage_zone):
		return
	var overlapped := _damage_zone.get_overlapping_areas()
	var area_origin := _damage_zone.global_transform.origin
	for body in overlapped:
		var parent: Node = body.get_parent()
		if parent.has_method("_damage"):
			var combatant_origin: Vector3 = parent.global_transform.origin
			var dis := area_origin.distance_to(combatant_origin)
			var dmg := _damage_calculate(dis, _weapon_base_config.damageCurve)
			parent._damage(dmg)

func _clean():
	queue_free()

func _exit_tree():
	if is_instance_valid(_computer):
		_computer.enforcer_assigned = false
	if is_instance_valid(_instrument):
		_instrument.enforcer_assigned = false
