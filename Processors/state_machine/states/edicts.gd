extends StateSingular

class_name Edicts

# Persistent
var forbid_substates := false
var force_edicts_refetch := true

func _init():
	name = "Edicts"

func _edict_execute(delta: float, subject):
	pass
