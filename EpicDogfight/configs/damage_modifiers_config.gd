extends Configuration

class_name DamageModifiersConfiguration

enum WARHEAD_TYPE {
	GENERAL				 = 0,
	PRESSURIZED			 = 1,
	SELF_IMPLODED		 = 2,
	FOWARD_CLUSTERED	 = 4,
	ARMOR_PIERCING		 = 8,
	ENERGY				 = 16,
}

# Persistent
var spaced				:= 1.0
var plated				:= 1.0
var composite			:= 1.0
var structure			:= 1.0
var fort				:= 1.0
var none				:= 1.0
var warhead_type: int	 = WARHEAD_TYPE.GENERAL

func _init():
	name = "DamageModifiersConfiguration"
