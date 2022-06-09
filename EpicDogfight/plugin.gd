tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"VTOLController",
		"Spatial",
		preload("res://addons/EpicDogfight/combatant/VTOLController.gd"),
		preload("res://addons/EpicDogfight/icons/brain1.png")
	)
#	add_autoload_singleton("TacticalCombatNetwork",
#		"res://addons/EpicDogfight/misc/team_network.gd")
	
func _exit_tree():
	remove_custom_type("VTOLController")
#	remove_autoload_singleton("TacticalCombatNetwork")
