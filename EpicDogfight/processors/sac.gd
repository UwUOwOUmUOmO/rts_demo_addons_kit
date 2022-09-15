extends FlightComputer

class_name StandardAircraftComputer

# Persistent
var edicts_handler: EdictsStateMachine = null
var state_machine: StateMachine = null

func _init():
	name = "StandardAircraftComputer"
	edicts_handler = EdictsStateMachine.new()
	state_machine = StateMachine.new()


