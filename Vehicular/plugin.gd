tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"VTOLFighterBrain",
		"KinematicBody",
		preload("res://addons/Vehicular/vtol_fighter.gd"),
		preload("res://addons/Vehicular/icons/fighter_icon.png")
	)
	add_custom_type(
		"NGADBrain",
		"KinematicBody",
		preload("res://addons/Vehicular/ngad_brain.gd"),
		preload("res://addons/Vehicular/icons/fighter_icon.png")
	)
	add_custom_type(
		"JetFighterBrain",
		"KinematicBody",
		preload("res://addons/Vehicular/jet_fighter.gd"),
		preload("res://addons/Vehicular/icons/fighter_icon.png")
	)
	
func _exit_tree():
	remove_custom_type("VTOLFighterBrain")
	remove_custom_type("JetFighterBrain")
