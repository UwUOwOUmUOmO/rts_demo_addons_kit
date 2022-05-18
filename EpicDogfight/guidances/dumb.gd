extends WeaponGuidance

class_name DumbGuidance

var detonation_time := 100.0
var time_elapsed := 0.0

func _boot_subsys():
	_computer = null

func _guide(delta: float):
	if time_elapsed + delta >= detonation_time:
		_finalize()
		_clean()
		return
	var distance := _velocity * delta
	global_translate((_direction * distance))
	time_elapsed += delta
