extends Configuration

class_name WeaponConfiguration

enum WEAPON_TYPE {KINETIC, ENERGY, UNKNOWN}
enum LAUNCHER_TYPE {SEMI, BURST, AUTO, UNKNOWN}
enum GUIDANCE {SEMI, HEAT, ACTIVE, NA}

var weapon_name 				:= ""
var rounds 						:= 0
var description 				:= ""
var firable 					:= true
var priority 					:= 0
var weaponType: int 			= WEAPON_TYPE.UNKNOWN
var weaponLauncherType: int 	= LAUNCHER_TYPE.UNKNOWN
var weaponGuidance: int 		= GUIDANCE.NA
var loadingTime 				:= 1.0

var minLaunchRange				:= 	10.0
var maxLaunchRange				:=	100.0
var travelTime					:=	200.0
var travelSpeed					:=	100.0
var heatThreshold				:=	10.0
var detonateDistance			:= 	3.0
var seekingAngle				:=	0.0
var homingRange					:=	0.0
var dvConfig					:=	VTOLConfiguration.new()

var damageModifier: Dictionary	= {
	"none": 		1.0,
	"light": 		1.0,
	"plating": 		1.0,
	"heavy": 		1.0,
	"building": 	1.0,
}

# func _get_property_list() -> Array:
# 	var modified := [
# 		{"name": "dvConfig", "class_name": "Resource",\
# 		"type": 17, "hint": 0, "hint_string": "", "usage": 1 }
# 	]
# 	return modified

func _init():
	._init()
	name = "WeaponConfiguration"
	return self
