tool
extends EditorPlugin

const TREE_EDITOR_UI := \
	preload("res://addons/BehaviorTree/ui/tree_editor.tscn")

const FILE_SELECTOR :=\
	preload("res://addons/BehaviorTree/ui/tree_editor_fd.gd")
const EDITOR_THEME :=\
	preload("res://addons/BehaviorTree/ui/graphics" +
			"/editor_theme_no_font.theme")


var editor_instance: Control = null
var file_selector: TreeEditorFileDialog = null

func _enter_tree():
	editor_instance = TREE_EDITOR_UI.instance()
	file_selector = FILE_SELECTOR.new()
	file_selector.theme = EDITOR_THEME
	add_child(file_selector)
	add_control_to_bottom_panel(editor_instance, "Behavior Tree")
	editor_instance.filesaver_dialog = file_selector
	file_selector.connect("file_selected", editor_instance,\
		"_on_FileSaver_file_selected")

func _exit_tree():
	file_selector.free()
	editor_instance.free()
	remove_control_from_bottom_panel(editor_instance)
