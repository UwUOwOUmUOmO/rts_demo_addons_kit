extends AirInstrument

class_name GeneralAirInstrument

const LOCK_ON_MAX_JITTER = deg2rad(6.0)

# Volatile
var radar_activated := true
var rng: RandomNumberGenerator = null
var rmd_squared := 0.0

var radar_cycle := 2.0

# Persistent
var radar_frequency := 0.5 setget set_rf, get_rf
var radar_max_distance := 0.0 setget set_rmd, get_rmd
var max_detection_velocity := 2000.0
var lock_on_detection_accuracy := 0.6
var radar_detection_curve: Curve = preload("general_detection_curve.res")

func set_rf(rf: float):
	radar_frequency = rf
	radar_cycle = 1.0 / rf

func get_rf():
	return radar_frequency

func set_rmd(rmd: float):
	radar_max_distance = rmd
	rmd_squared = rmd * rmd

func get_rmd():
	return radar_max_distance

func _boot():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	green_light = true
	_activate_radar()

func _compute(delta: float):
	pass

func _activate_radar():
	while not terminated:
		if radar_activated and green_light:
			_radar_ping()
		yield(tree.create_timer(radar_cycle), "timeout")

func _radar_ping():
	var clist := _get_all_combatants()
	detect_aircraft(clist)

func lock_on_handler(target):
	if target is Combatant:
		var actual_craft: VTOLFighterBrain = host.assigned_combatant
		var actual_dir: Vector3 = actual_craft.global_transform.origin\
			.direction_to(target.global_transform.origin)
		var jitter := clamp(LOCK_ON_MAX_JITTER * (1.0 - lock_on_detection_accuracy),\
			0.0001, 1.0)
		var flux_x := rng.randf_range(-jitter, jitter)
		var flux_y := rng.randf_range(-jitter, jitter)
		var jittered_dir: Vector3 = actual_dir + Vector3(flux_x, 0.0, flux_y)
		emit_signal("__lock_on_detected", jittered_dir)

# COMPROMISE: get distance
func is_aircraft_detected(boogie: VTOLFighterBrain) -> bool:
	var actual_craft: VTOLFighterBrain = host.assigned_combatant
	if not is_instance_valid(actual_craft):
		return false
	var distance: float = actual_craft\
		.global_transform.origin.distance_to(boogie\
		.global_transform.origin)
	var percentage := distance / radar_max_distance
	if percentage > 1.0:
		return false
	var reversed_scale := radar_detection_curve.interpolate(percentage)
	var v_threshold: float = max_detection_velocity * (1.0 - reversed_scale)\
		* (1.0 / boogie._vehicle_config["radarSignature"])
	if boogie.currentSpeed >= v_threshold:
		return true
	else:
		return false

func detect_aircraft(clist: Array) -> void:
	for c in clist:
		var combatant: VTOLFighterBrain = c
		if not is_instance_valid(combatant):
			continue
		if is_aircraft_detected(combatant):
			if combatant._vehicle_config["radarSignature"] < PROJECTILE_SIGNATURE:
				emit_signal("__inbound_projectile", combatant)
			else:
				emit_signal("__vehicle_detected", combatant)

func _get_all_combatants() -> Array:
	var list := []
	var current_tree = tree.current_scene
	var children: Array = current_tree.get_children()
	for c in children:
		if c is Combatant:
				list.append(c)
	return list

func _import(config: Dictionary) -> void:
	._import(config)
	set_rf(config["radar_frequency"])
	set_rmd(config["radar_max_distance"])
	max_detection_velocity = config["max_detection_velocity"]
	lock_on_detection_accuracy = config["lock_on_detection_accuracy"]
	var curve := load(config["radar_detection_curve"])
	if curve is Curve:
		radar_detection_curve = curve

func _export() -> Dictionary:
	var original := ._export()
	var re := {
		"radar_frequency": get_rf(),
		"radar_max_distance": get_rmd(),
		"max_detection_velocity": max_detection_velocity,
		"lock_on_detection_accuracy": lock_on_detection_accuracy,
		"radar_detection_curve": radar_detection_curve.resource_path,
	}
	return dictionary_append(original, re)

func _reset_volatile():
	._reset_volatile()
	radar_activated = true
	rng  = null
	rmd_squared = 0.0
