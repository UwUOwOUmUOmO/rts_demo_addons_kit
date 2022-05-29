extends BTLeaf

func _tick(agent: Node, blackboard: Blackboard):
	if not is_instance_valid(blackboard.get_data("target")):
		return fail()
	return succeed()
