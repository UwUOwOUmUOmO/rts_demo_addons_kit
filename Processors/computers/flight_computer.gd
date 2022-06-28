extends CombatComputer

class_name FlightComputer

enum DEVICE_TYPE { NA, AIRCRAFT, MISSILE }

const DEFAULT_DEVICE: int = DEVICE_TYPE.AIRCRAFT
const DEFAULT_DEVICE_STR := "AIRCRAFT"

# Persistent
var type := DEFAULT_DEVICE

func _init():
	._init()
	name = "FlightComputer"
	return self
