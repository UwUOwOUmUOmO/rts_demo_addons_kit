extends Serializable

class_name PilotConfiguration

enum AIRCRAFT_TYPE { UNKNOWN, STRIKER, EWA, DRONE, BOMBER, AUXILLARY, FIGHTER }
enum STATS_LIST {
	REACTION_SPEED = 1,
	REACTION_TIME = 2,
}

const BASE_MAIN_BONUS		:= 2.5
const BASE_DEFICIENCY		:= 0.4
const REACTION_SPEED_MOD	:= 1.0
const MAX_REACTION_SPEED	:= 1.0
# Volatile
var bake_after_set := true
var piloting: int = AIRCRAFT_TYPE.UNKNOWN
var base_coef := -1.0

# Persistent
var pilot_profile := PilotProfile.new()
var baked_stats := {
	"reaction_speed": 0.0,
	"reaction_time": 0.0,
}

var base_efficiency := 1.0 setget set_base_eff
var current_proficience: PoolRealArray = [
	0.0, 0.0, 0.0,
	0.0, 0.0, 0.0,
] setget set_curr_proef
var skills_list: PoolStringArray = [
	
]
var current_main: int = AIRCRAFT_TYPE.UNKNOWN
var main_bonus := BASE_MAIN_BONUS setget set_bonus
var main_deficiency := BASE_DEFICIENCY setget set_deficit

var base_reaction_time  := 0.3 setget set_brt

func set_base_eff(val: float):
	base_efficiency = val
	bake_stuff()

func set_curr_proef(val: PoolRealArray):
	current_proficience = val
	bake_stuff()

func set_main(val: int):
	current_main = val
	bake_stuff()

func set_bonus(val: float):
	main_bonus = val
	bake_stuff()

func set_deficit(val: float):
	main_deficiency = val
	bake_stuff()

func set_brt(val: float):
	base_reaction_time = val
	bake_stuff()

func bake_stuff():
	if bake_after_set:
		bake_base_coef()

func _init():
	
	name = "PilotConfiguration"
	remove_properties(["piloting", "base_coef"])
	no_deep_scan.append("baked_stats")
	return self

func check_special_behavior(key: String) -> bool:
	if base_coef == -1.0:
		bake_base_coef()
	if key == "reaction_speed":
		var rs := base_reaction_time * (1.0 / base_coef) \
			* REACTION_SPEED_MOD
		rs = clamp(rs, 0.01, MAX_REACTION_SPEED)
		baked_stats[key] = rs
		return true
	return false

func bake_base_coef():
	# Unified stats formula:
	# baked_stat = (base_ef + current_proef) * modifier * base_stat
	base_coef = base_efficiency + current_proficience[piloting]
	base_coef = clamp(base_coef, 0.001, INF)
	if piloting != current_main:
		base_coef *= main_deficiency
	else:
		base_coef *= main_bonus

func bake_standard(key: String):
	if check_special_behavior(key):
		return
	var base_key := ("base_" + key)
	if not base_key in self:
		Out.print_error("PilotConfigurration does not contain property: " \
			+ base_key, get_stack())
		return
	if base_coef == -1.0:
		bake_base_coef()
	baked_stats[key] = get(base_key) * base_coef

func rebake_stats(s_enum: int):
	var iter := 0
	for en in STATS_LIST:
		if s_enum & en:
			bake_standard(baked_stats.keys()[iter])
		iter += 1

func rebake_stats_all():
	var iter := 0
	for en in STATS_LIST:
		bake_standard(baked_stats.keys()[iter])
		iter += 1
