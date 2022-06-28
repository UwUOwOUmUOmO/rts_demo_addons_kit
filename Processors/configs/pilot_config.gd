extends Configuration

class_name PilotConfiguration

enum AIRCRAFT_TYPE { UNKNOWN, STRIKER, EWA, DRONE, BOMBER, AUXILLARY, FIGHTER }

const BASE_MAIN_BONUS := 2.5
const BASE_DEFICIENCY := 0.4

# Persistent
var base_proficiency := 1.0
var current_proficience: PoolRealArray = [
	0.0, 0.0, 0.0,
	0.0, 0.0, 0.0,
]
var skills_list: PoolStringArray = [
	
]
var current_main: int = AIRCRAFT_TYPE.NA
var main_bonus := 1.0
var main_deficiency := 1.0

func _init():
	._init()
	name = "PilotConfiguration"
	return self
