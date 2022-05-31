extends FlightComputer

class_name BTF_Computer

#const vtol_bt_packed := \
#	preload("../behavior_trees/vtol_computer/VTOLComputerBT.tscn")

func _boot():
	if is_instance_valid(host):
		if host is VTOLController:
			initialize()
			all_check = true

func initialize():
#	behavior_tree = vtol_bt_packed.instance()
#	blackboard = Blackboard.new()
#	host.add_child(behavior_tree)
#	host.add_child(blackboard)
#	blackboard.set_data("combatant", host.assigned_combatant)
#	behavior_tree.blackboard = blackboard
#	behavior_tree.agent = host
#	behavior_tree.is_active = true
	pass

func _compute(delta: float):
	return
