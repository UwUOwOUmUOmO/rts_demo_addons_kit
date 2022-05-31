extends Node

class_name WeaponHandler

signal __out_of_ammo()

const TIMER_ROLLBACK	:= 3600.0

var use_physics_process := true
var override_compensation := false
var compensator_autosetup := false
var compensation := 0.0

var weapon_name := ""
var profile: WeaponProfile = null setget set_profile, get_profile
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
# 1: Barrage
var launch_method := 0
var reserve := 0
var loading_time := 1.0
var charge_rate := 0.0
var last_hardpoint := -1
var inherited_speed := 0.0

var timer := 0.0
var green_light := false

func set_profile(p: WeaponProfile):
	profile = p
	weapon_name = p.name
	reserve = p.rounds
	loading_time = p.loadingTime

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
	if profile.weaponGuidance == WeaponProfile.GUIDANCE.NA:
		if compensation <= profile.weaponConfig["travelTime"]:
			if angle_check():
				return true
			else:
				return false
		else:
			return false
	else:
		var distance: float = hardpoints[last_hardpoint].global_transform.origin\
			.distance_to(target.global_transform.origin)
		if distance <= profile.weaponProfile["homingRange"]:
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
		print_stack()
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
	if profile.weaponGuidance == WeaponProfile.GUIDANCE.NA:
		guidance = DumbGuidance.new()
		instancing_result = guidance_instancing(guidance)
		var max_travel_time: float = profile.weaponConfig["travelTime"]
		var actual_comp := 0.0
		if override_compensation:
			actual_comp = compensation
		else:
			actual_comp = compensator.compensation
		guidance.detonation_time = clamp(actual_comp, 0.0, max_travel_time)
	else:
		if profile.weaponGuidance == WeaponProfile.GUIDANCE.SEMI\
			or profile.weaponGuidance == WeaponProfile.GUIDANCE.ACTIVE:
			guidance = HomingGuidance.new()
		elif profile.weaponGuidance == WeaponProfile.GUIDANCE.HEAT:
			guidance = ForwardLookingGuidance.new()
			guidance.heat_threshold = profile.weaponConfig["heatThreshold"]
			if profile.weaponConfig["seekingAngle"] != 0.0:
				guidance.seeking_angle  = profile.weaponConfig["seekingAngle"]
		instancing_result = guidance_instancing(guidance)
		guidance.set_range(profile.weaponConfig["homingRange"])
		guidance.set_profile(profile.weaponConfig["vtolProfile"])
		guidance.set_ddistance(profile.weaponConfig["detonateDistance"])
		guidance.self_destruct_time = profile.weaponConfig["travelTime"]
		guidance.inherited_speed = inherited_speed
		guidance.target = target
	if instancing_result is bool:
		if not instancing_result:
			push_error("Failed to instance guidance")
			print_stack()
			return
	guidance._velocity = profile.weaponConfig["travelSpeed"]
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

func fire_once(delta: float):
	var last_fire := timer
	if launch_method == 1:
		# Barrage
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
	else:
		# Cycle
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
	compensator.projectile_speed = profile.weaponConfig["travelSpeed"]
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
