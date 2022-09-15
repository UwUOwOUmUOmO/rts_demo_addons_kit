extends CombatantController

class_name VTOLController

func _init():
	_set_computer(StandardAircraftComputer.new())
	_set_instrument(GeneralAirInstrument.new())
