extends WeaponGuidance

class_name DumbGuidance

var detonation_time := 100.0
var time_elapsed := 0.0

func _guide(delta: float):
	if time_elapsed + delta >= detonation_time:
		_finalize()
		_clean()
		return
	var distance := _velocity * delta
	var a := global_transform.origin
	global_translate((_direction * distance))
	var b := global_transform.origin
	time_elapsed += delta
