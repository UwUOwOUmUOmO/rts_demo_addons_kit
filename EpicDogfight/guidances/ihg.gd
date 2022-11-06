extends WeaponGuidance

class_name IntegratedHomingGuidance

const DEFAULT_SEEKING_ANGLE = deg2rad(180.0)
var COMPUTE_DELAY: int = clamp(ProjectSettings.get_setting("game/compute_delay"), 1, 5)
# const CONTROLLER_DEFAULT_SIGNALS := {
# 	"__lock_on":		"lock_on_handler",
# 	"__loose_lock":		"loose_lock_handler",
# }
# signal __lock_on(source, tar)
# signal __loose_lock(source, tar)

# Out-bound links
var handler = null
var embedded_system: SimpleIntegratedMissilePerformer = null
var target: Spatial = null setget set_target

# Settings
var proximity_mode: int = WeaponConfiguration.PROXIMITY_MODE.SPATIAL
var projectile_type: int = AirCombatant.PROJECTILE_TYPE.AAM
var projectile_profile: AircraftConfiguration = null\
	setget set_profile, get_profile
var active_range := 100.0 setget set_range, get_range
var detonation_distance := 1.0 setget set_ddistance, get_ddistance
var inherited_speed := 0.0
var self_destruct_time := 5.0
var self_destruct_clock := 0.0
var guided := false setget set_guided, get_guided
var seeking_angle := DEFAULT_SEEKING_ANGLE

# Volatile
var active_range_squared := 10000.0
var detonation_distance_squared := 1.0

func set_target(new_target: Spatial):
	if new_target == target: return
	target = new_target
	if is_ready: embedded_system.target = target

func set_profile(p: AircraftConfiguration):
	var new_profile := AircraftConfiguration.new()
	new_profile.copy(p)
	projectile_profile = new_profile

func get_profile():
	return projectile_profile

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

func set_guided(g: bool):
	guided = g

func get_guided():
	return guided

func self_destruct_handler(delta: float):
	if self_destruct_clock + delta > self_destruct_time:
		_finalize()
		return
	else:
		self_destruct_clock += delta

func proximity_check(distance_squared: float) -> bool:
	if distance_squared < detonation_distance_squared and _armed:
		_finalize()
		return true
	else:
		return false

func angle_track(delta: float):
	var fwd_vec: Vector3 = -global_transform.basis.z
	var target_vec: Vector3 = global_transform.origin\
		.direction_to(target.global_transform.origin)
	var distance_squared := global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	var angle := fwd_vec.angle_to(target_vec)
	var pc_check := false
	var target_valid := false
	if proximity_mode == WeaponConfiguration.PROXIMITY_MODE.SPATIAL:
		pc_check = proximity_check(distance_squared)
		if pc_check:
			return
	if angle <= seeking_angle\
			and distance_squared <= active_range_squared:
		if proximity_mode == WeaponConfiguration.PROXIMITY_MODE.FORWARD:
			pc_check = proximity_check(distance_squared)
			if pc_check:
				return
		target_valid = true
	elif proximity_mode == WeaponConfiguration.PROXIMITY_MODE.DELAYED:
		pc_check = proximity_check(distance_squared)
		if pc_check:
			return
	embedded_system.allow_turn = target_valid
	# emit_signal("__loose_lock", self, target)

func self_setup():
	set_range(_weapon_base_config.homingRange)
	set_profile(_weapon_base_config.dvConfig)
	set_ddistance(_weapon_base_config.proximity)
	proximity_mode = _weapon_base_config.weaponProximityMode
	self_destruct_time = _weapon_base_config.travelTime
	if _weapon_base_config.seekingAngle > 0.0:
		seeking_angle = _weapon_base_config.seekingAngle

func _guide(delta: float):
	var frame := Engine.get_idle_frames()
	if Engine.is_in_physics_frame():
		frame = Engine.get_physics_frames()
	if frame % COMPUTE_DELAY != 0: return
	delta *= COMPUTE_DELAY
	embedded_system.ticks(delta)
	if not is_instance_valid(target):
		embedded_system.allow_turn = false
		# return
	else:
		angle_track(delta)
	self_destruct_handler(delta)

func simp_profile_setup():
	embedded_system.max_speed = projectile_profile.max_speed
	embedded_system.accel = projectile_profile.acceleration
	embedded_system.fixed_turn_rate = projectile_profile.turnRate
	embedded_system.inherited_speed = inherited_speed

func _signals_init():
	Utilities.SignalTools.connect_from(self, _projectile, \
		PROJECTILE_DEFAULT_SIGNALS, true)

func simp_setup():
	embedded_system = SimpleIntegratedMissilePerformer.new()
	embedded_system.target = target
	embedded_system.host = self
	simp_profile_setup()
	var loc := global_transform.origin
	var fwd := _barrel + _direction
	global_translate(_barrel - loc)
	look_at(fwd, Vector3.UP)
	_projectile = _weapon_base_config.projectile.instance()
	add_child(_projectile)
	_projectile.translation = Vector3.ZERO
#	_projectile.look_at(fwd, Vector3.UP)

func _guidance_init(move := true):
	self_setup()
	simp_setup()
	_signals_init()
	_initialize()
	_boot_subsys()
	is_ready = true
	# ._guidance_init(move)

func _finalize():
	._finalize()
	while is_instance_valid(_projectile): yield(Out.timer(1.0), "timeout")
	queue_free()

func switch_on():
	.switch_on()
	embedded_system.engage()
