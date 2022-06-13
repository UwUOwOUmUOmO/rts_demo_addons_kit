extends CombatComputer

class_name FlightComputer

enum DEVICE_TYPE {AAF, AAM, AGM}

const DEFAULT_DEVICE = DEVICE_TYPE.AAF
const DEFAULT_DEVICE_STR = "AAF"

# Persistent
var type = DEFAULT_DEVICE

func _init():
	._init()
	name = "FlightComputer"
	return self
