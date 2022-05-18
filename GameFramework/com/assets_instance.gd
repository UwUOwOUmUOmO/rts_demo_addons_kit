extends Node

class_name AssetsInstance

var assets := []

func _exit_tree():
	free_all()

func free_all():
	var count := assets.size()
	for c in range(0, count):
		assets[c] = null
