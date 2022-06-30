extends Configuration

class_name DamageModifiersConfiguration

const MINIMUM_EFFICIENCY := 0.001
const DEFAULT_EFFICIENCY := 1.0
const MAXIMUM_EFFICIENCY := 60.0

# ARMOR_TYPE is blenable
# Example: armor: int = ARMOR_TYPE.PLATED + ARMOR_TYPE.COMPOSITE
enum ARMOR_TYPE {
	NA = 0,
	SPACED = 1,
	PLATED = 2,
	COMPOSITE = 4,
	STRUCTURE = 8,
	FORT = 16,
}

# Persistent
var spaced		:= 1.0
var plated		:= 1.0
var composite	:= 1.0
var structure	:= 1.0
var fort		:= 1.0
var none		:= 1.0
var special_behavior := {}

func _init():
	._init()
	name = "DamageModifiersConfiguration"
	return self

# efficiency <> ineptness
func get_damage_coefficiency(enum_val: int):
	var dmg_mod := 1.0
	var debuff := 1.0
	# Calculate the coeefficiency
	# If target has no armor, then calculating any further would be
	# a complete resource waste
	if enum_val & ARMOR_TYPE.NA:
		dmg_mod *= none
	else:
		if enum_val & ARMOR_TYPE.SPACED:
			dmg_mod *= spaced
		if enum_val & ARMOR_TYPE.PLATED:
			dmg_mod *= plated
		if enum_val & ARMOR_TYPE.COMPOSITE:
			dmg_mod *= composite
		if enum_val & ARMOR_TYPE.STRUCTURE:
			dmg_mod *= structure
		# If the armor is a FORT type, decrease the efficiency:
		if enum_val & ARMOR_TYPE.FORT:
			dmg_mod *= fort
			debuff *= 0.8
	return clamp(dmg_mod * debuff, MINIMUM_EFFICIENCY, MAXIMUM_EFFICIENCY)

func calculate_damage(base_damage: float, armor_type: int, armor_coef: float,\
		special_type := ""):
	if not special_type.empty():
		return special_dmg_calculation(armor_coef, special_type)
	var dmg: float = base_damage * (1.0 / armor_coef) \
		* get_damage_coefficiency(armor_type)
	return dmg

func special_dmg_calculation(armor_coef: float, param: String) -> float:
	if not special_behavior.has(param):
		Out.print_error("Special behavior \"{sb}\" not registered"\
			.format({"sb": param}), get_stack())
		return DEFAULT_EFFICIENCY
	var fref = special_behavior[param]
	if not fref.has_method("__is_mod_fr"):
		Out.print_error("Special behavior \"{sb}\" is not a ModifiedFuncRef"\
			.format({"sb": param}), get_stack())
		return DEFAULT_EFFICIENCY
	var re = fref.call_func(armor_coef)
	if not re is float:
		Out.print_error("Special behavior \"{sb}\" return non-float value"\
			.format({"sb": param}), get_stack())
		return DEFAULT_EFFICIENCY
	return re
