extends FlightComputer

class_name PilotController

# Persistent
var current_aircraft_type: int =\
	PilotConfiguration.AIRCRAFT_TYPE.UNKNOWN
var pilot_config = null setget set_pilot

# Trying my best to avoid cyclic reference
func set_pilot(pilot):
	if not pilot is Object:
		return
	elif not pilot.has_method("__is_config"):
		return
	elif not "PilotConfiguration" in pilot.name:
		return
	pilot_config = pilot

func _init():
	._init()
	name = "PilotController"
	return self

func _boot():
	._boot()

func _compute(delta: float):
	pass