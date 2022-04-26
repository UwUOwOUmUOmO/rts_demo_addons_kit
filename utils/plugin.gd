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


func _exit_tree():
	pass
