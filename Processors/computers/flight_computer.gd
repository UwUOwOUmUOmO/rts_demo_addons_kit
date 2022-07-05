extends CombatComputer

class_name FlightComputer

const DEFAULT_DEVICE: int = AirCombatant.PROJECTILE_TYPE.AIRCRAFT
const DEFAULT_DEVICE_STR := "AIRCRAFT"

# Persistent
var type := DEFAULT_DEVICE

func _init():
	
	name = "FlightComputer"
	return self

func _boot():
	pass

func _compute(delta):
	pass
