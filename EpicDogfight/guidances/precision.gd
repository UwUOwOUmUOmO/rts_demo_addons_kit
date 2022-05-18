extends HomingGuidance

class_name PrecisionGuidance

var site := Vector3.ZERO

func _set_guided(g: bool):
	if g:
		vtol._setCourse(site)
	else:
		dumb_control()

func _guide(delta: float):
	if vtol.distance_squared <= detonation_distance_squared:
		_finalize()
	else:
		self_destruct_handler(delta)

func _initialize():
	_set_guided(true)
	emit_signal("__armament_fired", self)
