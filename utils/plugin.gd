tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"LineDrawer",
		"ImmediateGeometry",
		preload("line_drawer.gd"),
		null
	)
	add_custom_type(
		"SimpleSpatialLOD",
		"Spatial",
		preload("lod.gd"),
		null
	)
	add_autoload_singleton(
		"SingletonManager",
		"res://addons/utils/singleton_manager.gd"
	)
	add_autoload_singleton(
		"OutputManager",
		"res://addons/utils/error_handler.gd"
	)

func _exit_tree():
	remove_custom_type("LineDrawer")
	remove_custom_type("SimpleSpatialLOD")
	remove_autoload_singleton("SingletonManager")
	remove_autoload_singleton("OutputManager")
