extends Resource

class_name Processor

var host = null
var tree: SceneTree = null
var use_physics_process := true
var system_shutdown := false
var enforcer_assigned := false

func _process(delta: float):
	if not use_physics_process:
		_compute(delta)

func _physics_process(delta: float):
	if use_physics_process:
		_compute(delta)

func _boot():
	pass

func _compute(delta: float):
	pass
