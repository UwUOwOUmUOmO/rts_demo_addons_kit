extends Node

class_name WeaponHandler

signal __out_of_ammo()

const TIMER_LIMIT		:= pow(2, 63)

const dumb_guidance 	:= preload("guidances/dumb.tscn")
const homing_guidance 	:= preload("guidances/homing.tscn")
const heat_huidance 	:= preload("guidances/heat.tscn")

var use_physics_process := true
var compensation := 0.0

var weapon_name := ""
var profile: WeaponProfile = null setget set_profile, get_profile
var compensator: DistanceCompensator = null
var carrier: Spatial = null
var target: Spatial = null
var projectile: PackedScene = null
var hardpoints := []
var hardpoints_last_fire: PoolRealArray = []
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
	hardpoints.resize(num)
	for c in range(0, num):
		if h_list.empty():
			hardpoints[c] = null
		else:
			hardpoints[c] = h_list[c]
		hardpoints_last_fire[c] = last_fire

func hardpoint_location(loc: int):
	return hardpoints[clamp(loc, 0, hardpoints.size() - 1)]

func last_hardpoint_location():
	return hardpoint_location(last_hardpoint)

func compensate():
	if not profile or not compensator or not carrier:
		return 0.0
	var projectile_vel: float = profile.weaponConfig["travelSpeed"]
	compensation = compensator.calculate_leading(projectile_vel,\
		carrier.global_transform.origin)
	return compensation

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
		printerr("Error: scene not ready")
		printerr(get_stack())
		return
	if g.get_parent():
		g.get_parent().remove_child(g)
	scene.call_deferred("add_child", g)
	while not g.get_parent():
		yield(get_tree(), "idle_frame")

func spawn_projectile(no: int):
	var guidance: WeaponGuidance
	if profile.weaponGuidance == WeaponProfile.GUIDANCE.SEMI\
			or profile.weaponGuidance == WeaponProfile.GUIDANCE.ACTIVE:
		guidance = homing_guidance.instance()
		guidance_instancing(guidance)
		guidance.set_range(profile.weaponConfig["homingRange"])
		guidance.set_profile(profile.weaponConfig["vtolProfile"].duplicate())
		guidance.set_ddistance(profile.weaponConfig["detonateDistance"])
		guidance.self_destruct_time = profile.weaponConfig["travelTime"]
		guidance.inherited_speed = inherited_speed
		guidance.target = target
	elif profile.weaponGuidance == WeaponProfile.GUIDANCE.HEAT:
		guidance = heat_huidance.instance()
		guidance_instancing(guidance)
		guidance.set_range(profile.weaponConfig["homingRange"])
		guidance.set_profile(profile.weaponConfig["vtolProfile"].duplicate())
		guidance.set_ddistance(profile.weaponConfig["detonateDistance"])
		guidance.self_destruct_time = profile.weaponConfig["travelTime"]
		guidance.inherited_speed = inherited_speed
		guidance.target = target
		guidance.heat_threshold = profile.weaponConfig["heatThreshold"]
		if profile.weaponConfig["seekingAngle"] != 0.0:
			guidance.seeking_angle  = profile.weaponConfig["seekingAngle"]
	else:
		guidance = dumb_guidance.instance()
		guidance_instancing(guidance)
		var max_travel_time: float = profile.weaponConfig["travelTime"]
		guidance.detonation_time = clamp(compensation, 0.0, max_travel_time)
	guidance._velocity = profile.weaponConfig["travelSpeed"]
	guidance._barrel = hardpoints[no].global_transform.origin
	var h: Spatial = hardpoints[no]
	var fwd_vec := -h.global_transform.basis.z
	var euler := h.global_transform.basis.get_euler()
	guidance._transform = hardpoints[no].global_transform
	guidance._direction = fwd_vec
	guidance._projectile_scene = projectile
	while not guidance.get_parent():
		yield(get_tree(), "idle_frame")
	guidance._start()

func fire_once(delta: float):
	if reserve <= 0:
		emit_signal("__out_of_ammo")
		return
	var last_fire := timer
	if launch_method == 1:
		# Barrage
		var hardpoints_count = hardpoints.size()
		for c in range(0, hardpoints_count):
			var time_elapsed := abs(last_fire - hardpoints_last_fire[c])
			if time_elapsed > loading_time:
				spawn_projectile(c)
				hardpoints_last_fire[c] = last_fire
				reserve -= 1
	else:
		# Cycle
		var current_hardpoint: int = last_hardpoint + 1
		if current_hardpoint >= hardpoints.size():
			current_hardpoint = 0
		var time_elapsed := abs(last_fire - hardpoints_last_fire[current_hardpoint])
		if time_elapsed > loading_time:
			spawn_projectile(current_hardpoint)
			hardpoints_last_fire[current_hardpoint] = last_fire
			last_hardpoint = current_hardpoint
			reserve -= 1
		else:
			current_hardpoint -= 1

func fire():
	green_light = not green_light

func _process(delta):
	if not use_physics_process and green_light:
		fire_once(delta)
	timer += delta
	if timer > TIMER_LIMIT:
		timer = 0.0

func _physics_process(delta):
	if use_physics_process and green_light:
		fire_once(delta)
