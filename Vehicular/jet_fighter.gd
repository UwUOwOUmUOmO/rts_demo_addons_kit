extends VTOLFighterBrain

# onready var orbit = preload("res://addons/Vehicular/misc/Spinner.tscn")
# var spinner: Spatial = null

# func _ready():
# 	previousYaw = global_transform.basis.get_euler().y
# 	spinner = orbit.instance()
# 	get_tree().current_scene.add_child(spinner)
# 	_vehicle_config["orbitLength"] = 100.0
# 	_vehicle_config["deadzone"] = 10.0

# func _exit_tree():
# 	if spinner != null:
# 		spinner.queue_free()

# func _setMovement():
# 	if global_transform.origin.distance_to(destination) <= _vehicle_config["deadzone"]:
# 		_vehicle_config["maxThrottle"] = 0.3
# 		var mp_speed: float = _vehicle_config["maxThrottle"] * _vehicle_config["maxSpeed"]
# 		spinner.speed = mp_speed / 100.0
# 		_setTracker(spinner)
# 	elif slowingRange >= distance:
# 		throttle = clamp(distance / slowingRange, _vehicle_config["minThrottle"], 1.0)
# 	else:
# 		if throttle != _vehicle_config["maxThrottle"]:
# 			throttle = _vehicle_config["maxThrottle"]
# 	_turn(destination)

# func _setCourse(des: Vector3):
# 	if not isMoving:
# 		_setMoving(true)
# 	if trackingTarget != null:
# 		trackingTarget = null
# 	_bakeDestination(des)
# 	spinner.translation = des

# func setOrbit():
# 	pass

# func setOrbitLength(l: float):
# 	_vehicle_config["orbitLength"] = l
# 	spinner.get_node("/Target").translation = l
