extends KinematicBody

class_name Combatant

var _trackable := true
var _controller = null
var _trackedBy = null
var _vehicle_config: Dictionary = {}
var _use_physics_process := true

var _heat_signature := 10.0

var currentSpeed := 0.0

func _exit_tree():
	queue_free()
