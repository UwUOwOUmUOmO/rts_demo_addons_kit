extends Configuration

class_name WeaponConfiguration

enum PROXIMITY_MODE { SPATIAL, FORWARD, DELAYED }
enum WEAPON_TYPE	{ UNKNOWN, KINETIC, ENERGY }
enum FIRE_MODE		{ UNKNOWN, SALVO, BARRAGE, CONTINUOUS }
enum GUIDANCE		{ NA, SEMI, FLG, ACTIVE, PRECISION }

var weapon_name 				:= ""
var description 				:= ""
var firable 					:= true
var rounds 						:= 0
var priority 					:= 0
var loadingTime 				:= 1.0
var baseDamage					:= 50.0
var weaponType: int 			 = WEAPON_TYPE.UNKNOWN
var weaponFireMode: int 		 = FIRE_MODE.UNKNOWN
var weaponGuidance: int 		 = GUIDANCE.NA
var weaponProximityMode: int	 = PROXIMITY_MODE.SPATIAL

var weaponSignature				:= 	0.9
var minLaunchRange				:= 	10.0
var maxLaunchRange				:=	100.0
var travelTime					:=	200.0
var travelSpeed					:=	100.0
var heatThreshold				:=	10.0
var proximity					:= 	3.0
var seekingAngle				:=	deg2rad(30.0)
var homingRange					:=	0.0
var dvConfig					:=	AircraftConfiguration.new()
var damageCurve: Curve			 = null
var damageModifier				:= DamageModifiersConfiguration.new()

func _init():
	._init()
	name = "WeaponConfiguration"
	return self
	
func _data_correction() -> bool:
	var re := ._data_correction()
	var org_weaponSignature := weaponSignature
	weaponSignature = clamp(weaponSignature, 0.05, 0.99)
	re = re and (weaponSignature == org_weaponSignature)
	return re
