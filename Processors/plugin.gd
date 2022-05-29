tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("ProcessorsSwarm",\
		"res://addons/Processors/processors_swarm.gd")

func _exit_tree():
	remove_autoload_singleton("ProcessorsSwarm")
