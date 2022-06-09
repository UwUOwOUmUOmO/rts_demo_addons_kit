tool
extends EditorPlugin

func _enter_tree():
#	add_autoload_singleton("LevelSingleton", "res://addons/GameFramework/level_singleton.gd")
	add_custom_type("LevelResourceRegister", "Resource",\
		preload("com/level_resource.gd"), preload("icons/level_res_icon.png"))
	
func _exit_tree():
#	remove_autoload_singleton("LevelSingleton")
	remove_custom_type("LevelResourceRegister")
