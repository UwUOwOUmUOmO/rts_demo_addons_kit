extends Reference

class_name WeaponProfile

enum WEAPON_TYPE {KINETIC, ENERGY, UNKNOWN}
enum LAUNCHER_TYPE {SEMI, BURST, AUTO, UNKNOWN}
enum GUIDANCE {SEMI, HEAT, ACTIVE, NA}

var name := ""
var rounds := 0
var description := ""
var firable := true
var priority := 0
var weaponType = WEAPON_TYPE.UNKNOWN
var weaponLauncherType = LAUNCHER_TYPE.UNKNOWN
var weaponGuidance = GUIDANCE.NA
var loadingTime := 1.0
var damageModifier := {
	"none": 		1.0,
	"light": 		1.0,
	"plating": 		1.0,
	"heavy": 		1.0,
	"building": 	1.0,
}
var weaponConfig := {
	"minLaunchRange":	10.0,
	"maxLaunchRange":	100.0,
	"travelTime":		200.0,
	"travelSpeed":		100.0,
	"heatThreshold":	10.0,
	"detonateDistance": 3.0,
	"seekingAngle":		0.0,
	"homingRange":		0.0,
	"vtolProfile":		{},
}

func weaponTypeParsing(s, reversed = false):
	if not reversed:
		if s == "KINETIC":
			return WEAPON_TYPE.KINETIC
		elif s == "ENERGY":
			return WEAPON_TYPE.ENERGY
		else:
			return WEAPON_TYPE.UNKNOWN
	else:
		if s == WEAPON_TYPE.KINETIC:
			return "KINETIC"
		elif s == WEAPON_TYPE.ENERGY:
			return "ENERGY"
		else:
			return "UNKNOWN"

func weaponLaunchingTypeParsing(s, reversed = false):
	if not reversed:
		if s == "SEMI":
			return LAUNCHER_TYPE.SEMI
		elif s == "BURST":
			return LAUNCHER_TYPE.BURST
		elif s == "AUTO":
			return LAUNCHER_TYPE.AUTO
		else:
			return LAUNCHER_TYPE.UNKNOWN
	else:
		if s == LAUNCHER_TYPE.SEMI:
			return "SEMI"
		elif s == LAUNCHER_TYPE.BURST:
			return "BURST"
		elif s == LAUNCHER_TYPE.AUTO:
			return "AUTO"
		else:
			return "UNKNOWN"

func guidanceParsing(s, reversed = false):
	if not reversed:
		if s == "SEMI":
			return GUIDANCE.SEMI
		elif s == "HEAT":
			return GUIDANCE.HEAT
		elif s == "ACTIVE":
			return GUIDANCE.ACTIVE
		else:
			return GUIDANCE.NA
	else:
		if s == GUIDANCE.SEMI:
			return "SEMI"
		elif s == GUIDANCE.HEAT:
			return "HEAT"
		elif s == GUIDANCE.ACTIVE:
			return "ACTIVE"
		else:
			return "NA"

func _import(info: Dictionary):
	name = info["name"]
	rounds = info["rounds"]
	description = info["description"]
	firable = bool(info["firable"])
	priority = info["priority"]
	weaponType = weaponTypeParsing(info["weaponType"])
	weaponLauncherType = weaponLaunchingTypeParsing(info["weaponLauncherType"])
	weaponGuidance = guidanceParsing(info["weaponGuidance"])
	loadingTime = info["loadingTime"]
	damageModifier = info["damageModifier"]
	weaponConfig = info["weaponConfig"]

func _export():
	var re := {
		"name": name,
		"rounds": rounds,
		"description": description,
		"firable": firable,
		"priority": priority,
		"weaponType": weaponTypeParsing(weaponType, true),
		"weaponLauncherType": weaponLaunchingTypeParsing(weaponLauncherType, true),
		"weaponGuidance": guidanceParsing(weaponGuidance, true),
		"loadingTime": loadingTime,
		"damageModifier": damageModifier,
		"weaponConfig": weaponConfig,
	}
	return re
