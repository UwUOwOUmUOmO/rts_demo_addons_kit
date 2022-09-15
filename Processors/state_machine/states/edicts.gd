extends StateSingular

class_name Edicts

# Persistent
var edict_name := ""
var edict_description := ""
var prioritized := false
var forbid_substates := false
var force_edicts_refetch := true

func _init():
	name = "Edicts"

func _edict_execute(delta: float, subject):
	pass

func edict_approve(_edict) -> bool:
	return true
