tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton(
		"LevelManager",
		"res://addons/GameFramework/level_manager.gd"
	)

func _exit_tree():
	remove_autoload_singleton("LevelManager")
