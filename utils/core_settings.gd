extends Node

var use_physics_process := true
var physics_fps: int = ProjectSettings.get_setting("physics/common/physics_fps")
var fixed_delta := 1.0 / float(physics_fps)
