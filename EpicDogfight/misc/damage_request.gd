extends Reference

class_name DamageRequest

var damage_target: Combatant = null
var base_damage := 0.0
var damage_mod: DamageModifiersConfiguration = null
func _init(tar: Combatant, dmg: float, mod: DamageModifiersConfiguration):
	damage_target = tar
	base_damage = dmg
	damage_mod = mod