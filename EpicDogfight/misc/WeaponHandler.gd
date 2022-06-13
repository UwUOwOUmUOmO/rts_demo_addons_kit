extends Node

class_name WeaponHandler

signal __out_of_ammo()

const TIMER_ROLLBACK	:= 3600.0

var use_physics_process := true
var override_compensation := false
var compensator_autosetup := false
var compensation := 0.0

var weapon_name := ""
var profile: WeaponConfiguration = null setget set_profile, get_profile
var compensator: DistanceCompensatorV2 = null
var carrier: Spatial = null
var target: Spatial = null
var projectile: PackedScene = null
var hardpoints := []
var hardpoints_last_fire: PoolRealArray = []
var hardpoints_activation: PoolIntArray = [] # 1 is activated, other is not
var angle_limit := deg2rad(1.0)

# METHODS:
# 0: Cycle
# 1: SALVO
var current_fire_mode: int = WeaponConfiguration.FIRE_MODE.BARRAGE
var reserve := 0
var loading_time := 1.0
var charge_rate := 0.0
var last_hardpoint := -1
var inherite_carrier_speed := true

var timer := 0.0
var green_light := false

func set_profile(p: WeaponConfiguration):
	profile = p
	weapon_name = p.weapon_name
	reserve = p.rounds
	loading_time = p.loadingTime
	current_fire_mode = profile.weaponFireMode

func get_profile():
	return profile

func set_hardpoints(num: int, h_list := []):
	var last_fire := timer
	hardpoints.clear()
	hardpoints_last_fire.resize(num)
	hardpoints_activation.resize(num)
	hardpoints.resize(num)
	for c in range(0, num):
		if h_list.empty():
			hardpoints[c] = null
		else:
			hardpoints[c] = h_list[c]
		hardpoints_last_fire[c] = last_fire
		hardpoints_activation[c] = 1

func hardpoint_location(loc: int):
	return hardpoints[clamp(loc, 0, hardpoints.size() - 1)]

func last_hardpoint_location():
	return hardpoint_location(last_hardpoint)

func angle_check():
	var no := 0
	if last_hardpoint >= hardpoints.size() or last_hardpoint <= 0:
		no = 0
	var current_hardpoint: Spatial = hardpoints[no]
	var direction := -current_hardpoint.global_transform.basis.z
	var target_dir: Vector3 = current_hardpoint.direction_to(target)
	if target_dir.angle_to(direction) <= angle_limit:
		return true
	return false

func clear_for_fire() -> bool:
	if profile.weaponGuidance == WeaponConfiguration.GUIDANCE.NA:
		if compensation <= profile.travelTime:
			if angle_check():
				return true
			else:
				return false
		else:
			return false
	else:
		var distance: float = hardpoints[last_hardpoint].global_transform.origin\
			.distance_to(target.global_transform.origin)
		if distance <= profile.homingRange:
			if angle_check():
				return true
			else:
				return false
		else:
			return false

func guidance_instancing(g: WeaponGuidance):
	var scene := get_tree().get_current_scene()
	if not scene:
		push_error("Error: scene not ready")
		return false
	if g.get_parent():
		g.get_parent().remove_child(g)
	scene.call_deferred("add_child", g)
	while not g.get_parent():
		yield(get_tree(), "idle_frame")
	return true

func spawn_projectile(no: int):
	var guidance: WeaponGuidance
	var instancing_result
	if profile.weaponGuidance == WeaponConfiguration.GUIDANCE.NA:
		guidance = DumbGuidance.new()
		instancing_result = guidance_instancing(guidance)
		var max_travel_time: float = profile.travelTime
		var actual_comp := 0.0
		if override_compensation:
			actual_comp = compensation
		else:
			actual_comp = compensator.compensation
		guidance.detonation_time = clamp(actual_comp, 0.0, max_travel_time)
	else:
		if profile.weaponGuidance == WeaponConfiguration.GUIDANCE.SEMI\
			or profile.weaponGuidance == WeaponConfiguration.GUIDANCE.ACTIVE:
			guidance = HomingGuidance.new()
		elif profile.weaponGuidance == WeaponConfiguration.GUIDANCE.HEAT:
			guidance = ForwardLookingGuidance.new()
			guidance.heat_threshold = profile.heatThreshold
			if profile.seekingAngle != 0.0:
				guidance.seeking_angle  = profile.seekingAngle
		instancing_result = guidance_instancing(guidance)
		guidance.set_range(profile.homingRange)
		guidance.set_profile(profile.dvConfig)
		guidance.set_ddistance(profile.detonateDistance)
		guidance.self_destruct_time = profile.travelTime
		if inherite_carrier_speed and "currentSpeed" in carrier:
			guidance.inherited_speed = carrier.currentSpeed
		guidance.target = target
	if instancing_result is bool:
		if not instancing_result:
			push_error("Error: Failed to instance guidance")
			return
	guidance._velocity = profile.travelSpeed
	guidance._barrel = hardpoints[no].global_transform.origin
	var h: Spatial = hardpoints[no]
	var fwd_vec := -h.global_transform.basis.z
	var euler := h.global_transform.basis.get_euler()
#	guidance._transform = hardpoints[no].global_transform
	guidance._direction = fwd_vec
	guidance._projectile_scene = projectile
	while not guidance.get_parent():
		yield(get_tree(), "idle_frame")
	guidance._start()

func is_out_of_ammo() -> bool:
	if reserve <= 0:
		emit_signal("__out_of_ammo")
		return true
	else:
		return false

func fire_once(delta := 0.0):
	var last_fire := timer
	if current_fire_mode == WeaponConfiguration.FIRE_MODE.SALVO:
		var hardpoints_count = hardpoints.size()
		for c in range(0, hardpoints_count):
			if hardpoints_activation[c] != 1:
				continue
			elif is_out_of_ammo():
				return
			var time_elapsed := abs(last_fire - hardpoints_last_fire[c])
			if time_elapsed > loading_time:
				spawn_projectile(c)
				hardpoints_last_fire[c] = last_fire
				reserve -= 1
	elif current_fire_mode == WeaponConfiguration.FIRE_MODE.BARRAGE:
		if is_out_of_ammo():
			return
		var current_hardpoint: int = last_hardpoint + 1
		if current_hardpoint >= hardpoints.size():
			current_hardpoint = 0
		if hardpoints_activation[current_hardpoint] != 1:
			return
		var time_elapsed := abs(last_fire -\
			hardpoints_last_fire[current_hardpoint])
		if time_elapsed > loading_time:
			spawn_projectile(current_hardpoint)
			hardpoints_last_fire[current_hardpoint] = last_fire
			last_hardpoint = current_hardpoint
			reserve -= 1
		else:
			current_hardpoint -= 1

func fire():
	green_light = not green_light

func setup():
	compensator = DistanceCompensatorV2.new()
	compensator.target = target
	compensator.barrel = carrier
	compensator.projectile_speed = profile.travelSpeed
	get_tree().current_scene.add_child(compensator)

func _ready():
	if compensator_autosetup:
		setup()

func _process(delta):
	if not use_physics_process and green_light:
		fire_once(delta)
	timer += delta
	if timer > TIMER_ROLLBACK:
		timer = 0.0

func _physics_process(delta):
	if use_physics_process and green_light:
		fire_once(delta)
