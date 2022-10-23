extends CombatantConfiguration

class_name AircraftConfiguration

var acceleration 				:= 1.0
var decceleration				:= -2.0
var speedSnapping				:= 1.0
var climbRate					:= 1.2
var minThrottle					:= 0.2
var maxThrottle					:= 1.0
var max_speed					:= 100.0
var rollAmplifier				:= 10.0
var pitchAmplifier				:= 0.07
var maxRollAngle				:= PI / 4.0
var maxPitchAngle				:= PI / 2.0
var turnRate					:= 0.05
var maxTurnRate					:= 0.05
var slowingAt					:= 0.3
var orbitError					:= 0.7
var deadzone					:= 3.0
var switchDesZonePerc			:= 0.1
var rollNormalizationSpeed		:= deg2rad(40.0)

# Min/max switchDesZone squared
var minSDZS						:= 625.0
var maxSDZS						:= 10000.0
var slowingTime					:= 0.07
var aerodynamic					:= 0.8
var radarSignature				:= 1.5
var heatSignature				:= 10.0
var weight						:= 10.0
var speedLossMod				:= 15.0

# func _get(property):
# 	match property:
# 		"acceleration":
# 			return rom.get_exclusive("acceleration", acceleration)
# 		"decceleration":
# 			return rom.get_exclusive("decceleration", decceleration)
# 		"speedSnapping":
# 			return rom.get_exclusive("speedSnapping", speedSnapping)
# 		"climbRate":
# 			return rom.get_exclusive("climbRate", climbRate)
# 		"minThrottle":
# 			return rom.get_exclusive("minThrottle", minThrottle)
# 		"maxThrottle":
# 			return rom.get_exclusive("maxThrottle", maxThrottle)
# 		"max_speed":
# 			return rom.get_exclusive("max_speed", max_speed)
# 		"rollAmplifier":
# 			return rom.get_exclusive("rollAmplifier", rollAmplifier)
# 		"pitchAmplifier":
# 			return rom.get_exclusive("pitchAmplifier", pitchAmplifier)
# 		"maxRollAngle":
# 			return rom.get_exclusive("maxRollAngle", maxRollAngle)
# 		"maxPitchAngle":
# 			return rom.get_exclusive("maxPitchAngle", maxPitchAngle)
# 		"turnRate":
# 			return rom.get_exclusive("turnRate", turnRate)
# 		"maxTurnRate":
# 			return rom.get_exclusive("maxTurnRate", maxTurnRate)
# 		"slowingAt":
# 			return rom.get_exclusive("slowingAt", slowingAt)
# 		"orbitError":
# 			return rom.get_exclusive("orbitError", orbitError)
# 		"deadzone":
# 			return rom.get_exclusive("deadzone", deadzone)
# 		"switchDesZonePerc":
# 			return rom.get_exclusive("switchDesZonePerc", switchDesZonePerc)
# 		"rollNormalizationSpeed":
# 			return rom.get_exclusive("rollNormalizationSpeed", rollNormalizationSpeed)
# 		"minSDZS":
# 			return rom.get_exclusive("minSDZS", minSDZS)
# 		"maxSDZS":
# 			return rom.get_exclusive("maxSDZS", maxSDZS)
# 		"slowingTime":
# 			return rom.get_exclusive("slowingTime", slowingTime)
# 		"aerodynamic":
# 			return rom.get_exclusive("aerodynamic", aerodynamic)
# 		"radarSignature":
# 			return rom.get_exclusive("radarSignature", radarSignature)
# 		"heatSignature":
# 			return rom.get_exclusive("heatSignature", heatSignature)
# 		"weight":
# 			return rom.get_exclusive("weight", weight)
# 		"speedLossMod":
# 			return rom.get_exclusive("speedLossMod", speedLossMod)
# 		_:
# 			return ._get(property)

# func _set(property, value):
# 	match property:
# 		"acceleration":
# 			if rom.set_exclusive("acceleration", value):
# 				acceleration = value
# 		"decceleration":
# 			if rom.set_exclusive("decceleration", value):
# 				decceleration = value
# 		"speedSnapping":
# 			if rom.set_exclusive("speedSnapping", value):
# 				speedSnapping = value
# 		"climbRate":
# 			if rom.set_exclusive("climbRate", value):
# 				climbRate = value
# 		"minThrottle":
# 			if rom.set_exclusive("minThrottle", value):
# 				minThrottle = value
# 		"maxThrottle":
# 			if rom.set_exclusive("maxThrottle", value):
# 				maxThrottle = value
# 		"max_speed":
# 			if rom.set_exclusive("max_speed", value):
# 				max_speed = value
# 		"rollAmplifier":
# 			if rom.set_exclusive("rollAmplifier", value):
# 				rollAmplifier = value
# 		"pitchAmplifier":
# 			if rom.set_exclusive("pitchAmplifier", value):
# 				pitchAmplifier = value
# 		"maxRollAngle":
# 			if rom.set_exclusive("maxRollAngle", value):
# 				maxRollAngle = value
# 		"maxPitchAngle":
# 			if rom.set_exclusive("maxPitchAngle", value):
# 				maxPitchAngle = value
# 		"turnRate":
# 			if rom.set_exclusive("turnRate", value):
# 				turnRate = value
# 		"maxTurnRate":
# 			if rom.set_exclusive("maxTurnRate", value):
# 				maxTurnRate = value
# 		"slowingAt":
# 			if rom.set_exclusive("slowingAt", value):
# 				slowingAt = value
# 		"orbitError":
# 			if rom.set_exclusive("orbitError", value):
# 				orbitError = value
# 		"deadzone":
# 			if rom.set_exclusive("deadzone", value):
# 				deadzone = value
# 		"switchDesZonePerc":
# 			if rom.set_exclusive("switchDesZonePerc", value):
# 				switchDesZonePerc = value
# 		"rollNormalizationSpeed":
# 			if rom.set_exclusive("rollNormalizationSpeed", value):
# 				rollNormalizationSpeed = value
# 		"minSDZS":
# 			if rom.set_exclusive("minSDZS", value):
# 				minSDZS = value
# 		"maxSDZS":
# 			if rom.set_exclusive("maxSDZS", value):
# 				maxSDZS = value
# 		"slowingTime":
# 			if rom.set_exclusive("slowingTime", value):
# 				slowingTime = value
# 		"aerodynamic":
# 			if rom.set_exclusive("aerodynamic", value):
# 				aerodynamic = value
# 		"radarSignature":
# 			if rom.set_exclusive("radarSignature", value):
# 				radarSignature = value
# 		"heatSignature":
# 			if rom.set_exclusive("heatSignature", value):
# 				heatSignature = value
# 		"weight":
# 			if rom.set_exclusive("weight", value):
# 				weight = value
# 		"speedLossMod":
# 			if rom.set_exclusive("speedLossMod", value):
# 				speedLossMod = value
# 		_:
# 			._set(property, value)

func _init():
	name = "AircraftConfiguration"
	return self
