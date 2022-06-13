extends Configuration

class_name PilotConfiguration

enum AIRCRAFT_TYPE { UNKNOWN, STRIKER, EWA, DRONE, BOMBER, AUXILLARY, FIGHTER }

var current_proficience: PoolRealArray = [
	0.0, 0.0, 0.0,
	0.0, 0.0, 0.0,
]

var current_main: int = AIRCRAFT_TYPE.NA

func _init():
	._init()
	name = "PilotConfiguration"
	return self
