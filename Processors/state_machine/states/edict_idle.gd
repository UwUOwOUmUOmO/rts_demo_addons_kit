extends Edicts

class_name EdictIdle

# Persistent
var auto_approve_new_edict := true

func _init():
	state_name = "Idle"

func edict_approve(_edict) -> bool:
	return auto_approve_new_edict
