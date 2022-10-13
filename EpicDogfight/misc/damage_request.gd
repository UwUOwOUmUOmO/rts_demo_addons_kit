extends Reference

class_name DamageRequest

var damage_target: Combatant = null
var base_damage := 0.0
var damage_mod: DamageModifiersConfiguration = null
var effect_list := []
func _init(tar: Combatant, dmg: float, \
	mod: DamageModifiersConfiguration, elist := []):
		damage_target = tar
		base_damage = dmg
		damage_mod = mod
		effect_list = elist
