extends BTBaseClass

class_name BehaviorTree

export(String, "Idle", "Physics") var cycle_type = "Idle"

var blackboard := {}

func _init():
	._init()
	name = "BehaviorTree"
