extends Serializable

class_name WarheadConfiguration

# Persistent
var base_damage := 0.0
var modifiers: DamageModifiersConfiguration = null

func _init():
	name = "WarheadConfiguration"
