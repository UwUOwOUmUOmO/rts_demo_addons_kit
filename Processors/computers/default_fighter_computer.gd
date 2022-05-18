extends FlightComputer

class_name DefaultFighterComputer

var all_check := false

func _boot():
	if is_instance_valid(host):
		if host is VTOLController:
			all_check = true

func _compute(delta: float):
	if not all_check:
		return

