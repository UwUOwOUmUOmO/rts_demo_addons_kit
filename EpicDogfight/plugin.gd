tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"VTOLController",
		"Spatial",
		preload("res://addons/EpicDogfight/VTOLController.gd"),
		preload("res://addons/EpicDogfight/icons/brain1.png")
	)
	
func _exit_tree():
	remove_custom_type("VTOLController")
