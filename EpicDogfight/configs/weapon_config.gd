extends Serializable

class_name WeaponConfiguration

enum PROXIMITY_MODE { SPATIAL, FORWARD, DELAYED }
enum WEAPON_TYPE	{ UNKNOWN, KINETIC, ENERGY }
enum FIRE_MODE		{ UNKNOWN, SALVO, BARRAGE, CONTINUOUS }
enum GUIDANCE		{ NA, SEMI, FLG, ACTIVE, PRECISION, IHG }

export var weapon_name 									:= ""
export var description 									:= ""
export var firable 										:= true
export var rounds 										:= 0
export var priority 									:= 0
export(float, 0.1, 120.0, 0.1) var loadingTime 			:= 1.0
export(float, 0.1, 9999.0, 0.1) var baseDamage			:= 50.0
export(WEAPON_TYPE) var weaponType: int 				 = WEAPON_TYPE.UNKNOWN
export(FIRE_MODE) var weaponFireMode: int 				 = FIRE_MODE.UNKNOWN
export(GUIDANCE) var weaponGuidance: int 				 = GUIDANCE.NA
export(PROXIMITY_MODE) var weaponProximityMode: int		 = PROXIMITY_MODE.SPATIAL

export(float, 0.1, 10.0, 0.1) var weaponArmTime			:= 0.3
export(float, 0.1, 3.0, 0.1) var weaponSignature		:= 0.9
export(float, 1.0, 1000.0, 0.1) var minLaunchRange		:= 10.0
export(float, 100.0, 1000000.0, 0.1) var maxLaunchRange	:= 100.0
export(float, 0.5, 120.0, 0.1) var travelTime			:= 200.0
export(float, 0.5, 10000.0, 0.1) var travelSpeed		:= 100.0
export(float, 1.0, 180.0, 0.1) var _seeking_angle		:= 30.0 setget set_seeking_angle_degree
export(float, 0.1, 50.0, 0.1) var heatThreshold			:= 10.0
export(float, 0.1, 500.0, 0.1) var proximity			:= 3.0
export(float, 1.0, 10000.0, 0.1) var homingRange		:= 0.0
export(Resource) var dvConfig							 = AircraftConfiguration.new()
export var damageCurve: Curve							 = null
export(Resource) var damageModifier						 = DamageModifiersConfiguration.new()
export var projectile: PackedScene						 = null

var seekingAngle := deg2rad(30.0)

func set_seeking_angle_degree(angle: float):
	_seeking_angle = angle
	seekingAngle = deg2rad(angle)

func _init():
	name = "WeaponConfiguration"
	return self
	
func _data_correction() -> bool:
	var re := ._data_correction()
	var org_weaponSignature := weaponSignature
	weaponSignature = clamp(weaponSignature, 0.05, 0.99)
	re = re and (weaponSignature == org_weaponSignature)
	return re
