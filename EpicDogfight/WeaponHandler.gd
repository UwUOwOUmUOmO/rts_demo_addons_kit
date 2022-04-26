extends Node

class_name WeaponHandler

const dumb_guidance 	:= preload("guidances/dumb.tscn")
const homing_guidance 	:= preload("guidances/homing.tscn")
const heat_huidance 	:= preload("guidances/heat.tscn")

var use_physics_process := false
var compensation := 0.0

var weapon_name := ""
var profile: WeaponProfile = null setget set_profile, get_profile
var compensator: DistanceCompensator = null
var carrier: Spatial = null
var target: Combatant = null
var projectile: PackedScene = null
var hardpoints := []
var hardpoints_last_fire: PoolIntArray = []

# METHODS:
# 0: Cycle
# 1: Barrage
var launch_method := 0
var reserve := 0
var loading_time := 1.0
var charge_rate := 0.0
var last_hardpoint := -1

var green_light := false

func set_profile(p: WeaponProfile):
	profile = p
	weapon_name = p.name
	reserve = p.rounds
	loading_time = p.loadingTime

func get_profile():
	return profile

func set_hardpoints(num: int, h_list := []):
	var last_fire := OS.get_unix_time()
	for c in range(0, num):
		hardpoints.clear()
		hardpoints_last_fire.resize(num)
		hardpoints.resize(num)
		if h_list.empty():
			hardpoints[c] = null
		else:
			hardpoints[c] = h_list[c]
		hardpoints_last_fire[c] = last_fire

func compensate():
	if not profile or not compensator or not carrier:
		return null
	var projectile_vel: float = profile.weaponConfig["travelSpeed"]
	compensation = compensator.calculate_leading(projectile_vel,\
		carrier.global_transform.origin)
	return compensation

func clear_for_fire() -> bool:
	if profile.weaponGuidance == WeaponProfile.GUIDANCE.NA:
		if compensation <= profile.weaponConfig["travelTime"]:
			return true
		else:
			return false
	else:
		var distance: float = hardpoints[last_hardpoint].global_transform.origin\
			.distance_to(target.global_transform.origin)
		if distance <= profile.weaponProfile["homingRange"]:
			return true
		else:
			return false

func spawn_projectile(no: int):
	var guidance: WeaponGuidance
	if profile.weaponGuidance == WeaponProfile.GUIDANCE.SEMI\
			or profile.weaponGuidance == WeaponProfile.GUIDANCE.ACTIVE:
		guidance = homing_guidance.instance()
		get_tree().get_current_scene().add_child(guidance)
		guidance.set_range(profile.weaponConfig["homingRange"])
		guidance.set_profile(profile.weaponConfig["vtolProfile"])
		guidance.detonation_distance.set_ddistance(profile.weaponConfig["detonateDistance"])
		guidance.self_destruct_time = profile.weaponConfig["travelTime"]
		guidance.target = target
	elif profile.weaponGuidance == WeaponProfile.GUIDANCE.HEAT:
		guidance = heat_huidance.instance()
		get_tree().get_current_scene().add_child(guidance)
		guidance.set_range(profile.weaponConfig["homingRange"])
		guidance.set_profile(profile.weaponConfig["vtolProfile"])
		guidance.detonation_distance.set_ddistance(profile.weaponConfig["detonateDistance"])
		guidance.self_destruct_time = profile.weaponConfig["travelTime"]
		guidance.target = target
		guidance.heat_threshold = profile.weaponConfig["heatThreshold"]
		if profile.weaponConfig["seekingAngle"] != 0.0:
			guidance.seeking_angle  = profile.weaponConfig["seekingAngle"]
	else:
		guidance = dumb_guidance.instance()
		get_tree().get_current_scene().add_child(guidance)
		var max_travel_time: float = profile.weaponConfig["travelTime"]
		guidance.detonation_time = clamp(compensation, 0.0, max_travel_time)
	guidance._velocity = profile.weaponConfig["travelSpeed"]
	guidance._barrel = hardpoints[no].global_transform.origin
	guidance._direction = -hardpoints[no].global_transform.basis.z
	guidance._projectile_scene = projectile
	guidance._start()

# THE USE OF UNIX TIME COULD LEAD TO SOME WACKY EXPLOITS
# I TOLD YOU
# UNIX TIME ONLY RECORD IN SECOND
func fire_once(delta: float):
	if reserve <= 0:
		return
	var last_fire := OS.get_unix_time()
	if launch_method == 1:
		# Barrage
		var hardpoints_count = hardpoints.size()
		for c in range(0, hardpoints_count):
			var time_elapsed := last_fire - hardpoints_last_fire[c]
			if time_elapsed > loading_time:
				spawn_projectile(c)
				hardpoints_last_fire[c] = last_fire
				reserve -= 1
	else:
		# Cycle
		var current_hardpoint: int = last_hardpoint + 1
		if current_hardpoint <= hardpoints.size():
			current_hardpoint = 0
		var time_elapsed := last_fire - hardpoints_last_fire[current_hardpoint]
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

func _physics_process(delta):
	if use_physics_process and green_light:
		fire_once(delta)
