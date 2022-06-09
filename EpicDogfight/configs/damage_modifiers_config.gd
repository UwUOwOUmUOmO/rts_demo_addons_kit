extends Configuration

class_name DamageModifiersConfiguration

const MINIMUM_EFFICIENCY := 0.001
const DEFAULT_EFFICIENCY := 1.0
const MAXIMUM_EFFICIENCY := 60.0

enum ARMOR_TYPE { LIGHT, SOLID, COMPOSITE, BUILDING, FORT, NA }

var light       := 1.0
var solid       := 1.0
var composite   := 1.0
var buidling    := 1.0
var fort        := 1.0
var none        := 1.0

var special_behavior := {}

func _init():
	exclusion_list.push_back("special_behavior")
	._init()
	name = "DamageModifiersConfiguration"
	return self

# efficiency <> ineptness
func get_damage_coefficiency(enum_val: int):
	var dmg_mod := 0.0
	match enum_val:
		ARMOR_TYPE.LIGHT:
			dmg_mod = light
		ARMOR_TYPE.SOLID:
			dmg_mod = solid
		ARMOR_TYPE.COMPOSITE:
			dmg_mod = composite
		ARMOR_TYPE.BUILDING:
			dmg_mod = buidling
		ARMOR_TYPE.FORT:
			dmg_mod = fort
		_:
			dmg_mod = none
	return clamp(dmg_mod, MINIMUM_EFFICIENCY, MAXIMUM_EFFICIENCY)

func calculate_damage(base_damage: float, armor_type: int, armor_coef: float,\
		special_type := ""):
	if not special_type.empty():
		return special_dmg_calculation(armor_coef, special_type)
	var dmg: float = base_damage * armor_coef\
		* get_damage_coefficiency(armor_type)
	return dmg

func special_dmg_calculation(armor_coef: float, param: String) -> float:
	if not special_behavior.has(param):
		push_error("Error: special behavior \"{sb}\" not registered"\
			.format({"sb": param}))
		return DEFAULT_EFFICIENCY
	var fref = special_behavior[param]
	if not fref is FuncRef:
		push_error("Error: special behavior \"{sb}\" is not a FuncRef"\
			.format({"sb": param}))
		return DEFAULT_EFFICIENCY
	var re = fref.call_func(armor_coef)
	if not re is float:
		push_error("Error: special behavior \"{sb}\" return non-float value"\
			.format({"sb": param}))
		return DEFAULT_EFFICIENCY
	return re
