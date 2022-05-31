extends Resource

class_name BehaviorTreeResource

export(Array) var graph_nodes_list = []

var behavior_tree_node: BehaviorTree = null
var blackboard := {}
var last_viewport_location := Vector2.ZERO

func to_headless() -> BTRHeadless:
	var headless := BTRHeadless.new()
	headless.behavior_tree = behavior_tree_node
	headless.blackboard = blackboard
	return headless
