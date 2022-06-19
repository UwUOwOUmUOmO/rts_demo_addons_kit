extends Spatial

class_name WeaponGuidance

signal __armament_fired(guidance)
signal __armament_detonated(guidance)

var _weapon_base_config: WeaponConfiguration = null

var _velocity := 0.0
var _barrel := Vector3.ZERO
var _direction := Vector3.ZERO
var _use_physics_process := true
var _projectile_scene: PackedScene = null
var _projectile: Spatial = null
var _computer: FlightComputer = null
var _instrument: AirInstrument = null
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
		_guide(delta)

func _computer_handler(delta: float, pp := false):
	if is_instance_valid(_computer):
		if pp:
			_computer._physics_process(delta)
		else:
			_computer._process(delta)
	if is_instance_valid(_instrument):
		if pp:
			_instrument._physics_process(delta)
		else:
			_instrument._process(delta)

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
	_clean()

func _clean():
	queue_free()

func _exit_tree():
	if is_instance_valid(_computer):
		_computer.enforcer_assigned = false
	if is_instance_valid(_instrument):
		_instrument.enforcer_assigned = false
