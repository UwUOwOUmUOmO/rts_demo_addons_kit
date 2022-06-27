extends Configuration

class_name WeaponConfiguration

enum WEAPON_TYPE	{ UNKNOWN, KINETIC, ENERGY }
enum FIRE_MODE		{ UNKNOWN, SALVO, BARRAGE, CONTINUOUS }
enum GUIDANCE		{ NA, SEMI, FLG, ACTIVE, PRECISION }

var weapon_name 			:= ""
var rounds 					:= 0
var description 			:= ""
var firable 				:= true
var priority 				:= 0
var weaponType: int 		 = WEAPON_TYPE.UNKNOWN
var weaponFireMode: int 	 = FIRE_MODE.UNKNOWN
var weaponGuidance: int 	 = GUIDANCE.NA
var loadingTime 			:= 1.0

var minLaunchRange			:= 	10.0
var maxLaunchRange			:=	100.0
var travelTime				:=	200.0
var travelSpeed				:=	100.0
var heatThreshold			:=	10.0
var detonateDistance		:= 	3.0
var seekingAngle			:=	0.0
var homingRange				:=	0.0
var dvConfig				:=	AircraftConfiguration.new()
var damageModifier			:= DamageModifiersConfiguration.new()

func _init():
	._init()
	name = "WeaponConfiguration"
	return self
