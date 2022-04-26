extends KinematicBody

class_name Combatant

var _trackable := true
var _controller = null
var _trackedBy: Combatant = null
var _vehicle_config := {}
var _use_physics_process := true

var _heat_signature := 10.0

func _exit_tree():
	queue_free()
