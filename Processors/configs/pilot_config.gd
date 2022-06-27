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
var skills_list := {
	1000: false,
	1001: false,
	1002: false,
	1003: false,
	1004: false,
	1005: false,
	1006: false,
	1007: false,
	1008: false,
	1009: false,
	1011: false,
	1012: false,
	1013: false,
	1014: false,
	1015: false,
	1016: false,
	1017: false,
	1018: false,
	
}
var current_main: int = AIRCRAFT_TYPE.NA
var main_bonus := 1.0
var main_deficiency := 1.0

func _init():
	._init()
	name = "PilotConfiguration"
	return self
