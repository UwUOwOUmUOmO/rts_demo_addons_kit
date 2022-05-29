extends Resource

class_name Processor

# Volatile
var host = null
var tree: SceneTree = null
var terminated := false
var enforcer_assigned := false

# Persistance
var use_physics_process := true


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

func _import(config: Dictionary) -> void:
	use_physics_process = config["use_physics_process"]

func _export() -> Dictionary:
	var re := {
		"use_physics_process": use_physics_process,
	}
	return re

func _reset_volatile() -> void:
	host = null
	tree  = null
	terminated = false
	enforcer_assigned = false

func save_resource(path: String, flag = 0):
	return ResourceSaver.save(path, self, flag)

static func dictionary_append(parent: Dictionary, inherited: Dictionary,\
		duplicated := false) -> Dictionary:
	# Inherited value will replace original value if duplicated
	var re: Dictionary
	if duplicated:
		re = parent.duplicate(true)
	else:
		re = parent
	for key in inherited:
		re[key] = inherited[key]
	return re
