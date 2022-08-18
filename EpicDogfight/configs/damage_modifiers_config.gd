extends Configuration

class_name DamageModifiersConfiguration

const MINIMUM_EFFICIENCY := 0.001
const DEFAULT_EFFICIENCY := 1.0
const MAXIMUM_EFFICIENCY := 60.0

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
