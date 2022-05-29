tool
extends EditorPlugin

#func _enter_tree():
#	add_custom_type("BehaviorTree", "Node",
#		preload("src/behavior_tree.gd"),
#		preload("icons/bt.svg")
#	)
#	add_custom_type("BT_Blackboard", "Node",
#		preload("src/blackboard.gd"),
#		preload("icons/blackboard.svg")
#	)
#	add_custom_type("BT_Node", "Node",
#		preload("src/bt_node.gd"),
#		preload("icons/btnode.svg")
#	)
#	#------------------------------------------------------------
#	add_custom_type("BT_Composite", "BTNode",
#		preload("src/btnodes/bt_composite.gd"),
#		preload("icons/btcomposite.svg")
#	)
#	add_custom_type("BT_Decorator", "BTNode",
#		preload("src/btnodes/bt_decorator.gd"),
#		preload("icons/btdecorator.svg")
#	)
#	add_custom_type("BT_Leaf", "BTNode",
#		preload("src/btnodes/bt_leaf.gd"),
#		preload("icons/btleaf.svg")
#	)
#	#------------------------------------------------------------
#	add_custom_type("BT_Parallel", "BTComposite",
#		preload("src/btnodes/composites/bt_parallel.gd"),
#		preload("icons/btparallel.svg")
#	)
#	add_custom_type("BT_RandomSelector", "BTComposite",
#		preload("src/btnodes/composites/bt_random_selector.gd"),
#		preload("icons/btrndselector.svg")
#	)
#	add_custom_type("BT_RandomSequence", "BTComposite",
#		preload("src/btnodes/composites/bt_random_sequence.gd"),
#		preload("icons/btrndsequence.svg")
#	)
#	add_custom_type("BT_Selector", "BTComposite",
#		preload("src/btnodes/composites/bt_selector.gd"),
#		preload("icons/btselector.svg")
#	)
#	add_custom_type("BT_Sequence", "BTComposite",
#		preload("src/btnodes/composites/bt_sequence.gd"),
#		preload("icons/btsequence.svg")
#	)
#	#------------------------------------------------------------
#	add_custom_type("BT_Always", "BTDecorator",
#		preload("src/btnodes/decorators/bt_always.gd"),
#		preload("icons/btalways.svg")
#	)
#	add_custom_type("BT_Conditional", "BTDecorator",
#		preload("src/btnodes/decorators/bt_conditional.gd"),
#		preload("icons/btconditional.png")
#	)
#	add_custom_type("BT_Guard", "BTDecorator",
#		preload("src/btnodes/decorators/bt_guard.gd"),
#		preload("icons/btguard.svg")
#	)
#	add_custom_type("BT_Repeat", "BTDecorator",
#		preload("src/btnodes/decorators/bt_repeat.gd"),
#		preload("icons/btrepeat.svg")
#	)
#	add_custom_type("BT_RepeatUntil", "BTDecorator",
#		preload("src/btnodes/decorators/bt_repeat_until.gd"),
#		preload("icons/btrepeatuntil.svg")
#	)
#	add_custom_type("BT_Revert", "BTDecorator",
#		preload("src/btnodes/decorators/bt_revert.gd"),
#		preload("icons/btrevert.svg")
#	)
#	#------------------------------------------------------------
#	add_custom_type("BT_Wait", "BTLeaf",
#		preload("src/btnodes/leaves/bt_wait.gd"),
#		preload("icons/btwait.svg")
#	)
#
#func _exit_tree():
#	remove_custom_type("BehaviorTree")
#	remove_custom_type("BT_Blackboard")
#	remove_custom_type("BT_Node")
#	#---------------------------------------
#	remove_custom_type("BT_Composite")
#	remove_custom_type("BT_Decorator")
#	remove_custom_type("BT_Leaf")
#	#---------------------------------------
#	remove_custom_type("BT_Parallel")
#	remove_custom_type("BT_RandomSelector")
#	remove_custom_type("BT_RandomSequence")
#	remove_custom_type("BT_Selector")
#	remove_custom_type("BT_Sequence")
#	#---------------------------------------
#	remove_custom_type("BT_Always")
#	remove_custom_type("BT_Conditional")
#	remove_custom_type("BT_Guard")
#	remove_custom_type("BT_Repeat")
#	remove_custom_type("BT_RepeatUntil")
#	remove_custom_type("BT_Revert")
#	#---------------------------------------
#	remove_custom_type("BT_Wait")
