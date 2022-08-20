extends WeaponGuidance

class_name HomingGuidance

const CONTROLLER_DEFAULT_SIGNALS := {
	"__lock_on":		"lock_on_handler",
	"__loose_lock":		"loose_lock_handler",
}

signal __lock_on(source, tar)
signal __loose_lock(source, tar)

var handler = null
var vtol: VTOLFighterBrain = null
var target: Spatial = null

var proximity_mode: int = WeaponConfiguration.PROXIMITY_MODE.SPATIAL
var projectile_type: int = AirCombatant.PROJECTILE_TYPE.AAM
var vtol_profile: AircraftConfiguration = null\
	setget set_profile, get_profile
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

func set_profile(p: AircraftConfiguration):
	var new_profile := AircraftConfiguration.new()
	new_profile.copy(p)
	vtol_profile = new_profile

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

func proximity_check(distance_squared: float) -> bool:
	if distance_squared < detonation_distance_squared and _armed:
		_finalize()
		return true
	else:
		return false

func _guide(delta: float):
	if not is_instance_valid(target):
		dumb_control()
		self_destruct_handler(delta)
		return
	var distance_squared := vtol.global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	var target_valid := false
	if proximity_mode == WeaponConfiguration.PROXIMITY_MODE.SPATIAL:
		if proximity_check(distance_squared):
			return
	if (guided and handler.guided) or distance_squared <= active_range_squared:
		target_valid = true
		if vtol.trackingTarget != target:
			vtol.set_tracking_target(target)
			manual_control = false
			emit_signal("__lock_on", self, target)
		if proximity_mode == WeaponConfiguration.PROXIMITY_MODE.FORWARD:
			if proximity_check(distance_squared):
				return
	elif proximity_mode == WeaponConfiguration.PROXIMITY_MODE.DELAYED:
		if proximity_check(distance_squared):
			return
	if target_valid:
		dumb_control()
	
	self_destruct_handler(delta)

func dumb_control():
	if not manual_control:
		emit_signal("__loose_lock", self, target)
		vtol.useRudder = true
		manual_control = true

func self_destruct_handler(delta: float):
	if self_destruct_clock + delta > self_destruct_time:
		_finalize()
		return
	else:
		self_destruct_clock += delta

func _finalize():
	vtol._disabled = true
	._finalize()

func _clean():
	if _autofree_projectile:
		vtol.queue_free()
	queue_free()

func _initialize():
	._initialize()
	if not is_instance_valid(target):
		return
	if not target is Combatant:
		return
	Toolkits.SignalTools.connect_from(self, target._controller,
		CONTROLLER_DEFAULT_SIGNALS)

func self_setup():
	set_range(_weapon_base_config.homingRange)
	set_profile(_weapon_base_config.dvConfig)
	set_ddistance(_weapon_base_config.proximity)
	proximity_mode = _weapon_base_config.weaponProximityMode
	self_destruct_time = _weapon_base_config.travelTime

func _start(move := true):
	self_setup()
	vtol = VTOLFighterBrain.new()
	vtol._vehicle_config = vtol_profile
	vtol.device = AirCombatant.PROJECTILE_TYPE.MISSILE + projectile_type
	vtol._controller = self
	# var scene := get_tree().get_current_scene()
	# if scene:
	# 	scene.call_deferred("add_child", vtol)
	# else:
	# 	Out.print_error("Scene not ready", get_stack())
	# 	return
	LevelManager.template.add_peripheral(vtol)
	while vtol.get_parent() == null:
		yield(get_tree(), "idle_frame")
	vtol.global_translate(_barrel - vtol.global_transform.origin)
	vtol.inheritedSpeed = inherited_speed
	vtol.overdriveThrottle = 1.0
	vtol.look_at(vtol.translation + _direction, Vector3.UP)
	_projectile = _weapon_base_config.projectile.instance()
	vtol.add_child(_projectile)
	_projectile.owner = vtol
	_projectile.translation = Vector3.ZERO
	vtol.connect("__combatant_out_of_hp", self, "no_hp_handler")
	_signals_init()
	_initialize()
	_green_light = true
	_boot_subsys()

func no_hp_handler(_com):
	_projectile.premature_detonation_handler()
	_finalize()

func lock_on_handler(_tar):
	Out.print_error("This handler is not supposed to be used", \
		get_stack())

func loose_lock_handler(_tar):
	Out.print_error("This handler is not supposed to be used", \
		get_stack())
