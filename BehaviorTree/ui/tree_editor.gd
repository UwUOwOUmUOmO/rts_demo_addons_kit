tool
extends Control

const DEFAULT_AUTO_SAVE_INTERVAL := 180

signal editor_ready(isReady)

onready var editor_handler := $EditorHandler
onready var main_container := $MainContainer
onready var nofile_container := $NoFileContainer
onready var filesaver_dialog = null

onready var filepath_line_edit := $MainContainer/FileIndicator/FilePath
onready var autosave_chk := $MainContainer/FileIndicator/AutosaveChk

export(int) var autosave_interval = DEFAULT_AUTO_SAVE_INTERVAL
export(bool) var is_debugging := false

var active_path := ""
var active_file: BehaviorTreeResource = null

func _ready():
	nofile_container.visible = true
	main_container.visible = false
	active_file = BehaviorTreeResource.new()
	connect("editor_ready", editor_handler, "__editor_ready_handler")
	if is_debugging:
		filesaver_dialog = $FileSaver

func _exit_tree():
	$MainContainer/Splitter/NodeBrowser.clear()

func add_filter():
	while not is_instance_valid(filesaver_dialog):
		yield(get_tree(), "idle_frame")
	filesaver_dialog.add_filter("*.res")


func switch_to_editor(new_res: BehaviorTreeResource):
	active_file = new_res
	filepath_line_edit.text = active_path
	nofile_container.visible = false
	main_container.visible = true
	emit_signal("editor_ready", true)

func save_file(path: String):
	var t := Processor.new()
	t.use_physics_process = false
	active_file.debug2["Testies"] = t
	var err := ResourceSaver.save(path, active_file)
	if not err == OK:
		Out.print_error("Failed to save resource at path: "\
			+ path, get_stack())

func open_file(path: String):
	var loader := ResourceLoader.load_interactive(path)
	while true:
		var err := loader.poll()
		if err == ERR_FILE_EOF:
			var res = loader.get_resource()
			if not res is BehaviorTreeResource:
				Out.print_error(("Resource at path"+
					"{p} is not a BehaviorTreeResource").format({"p": path}),\
					get_stack())
				return
			else:
				active_path = path
				switch_to_editor(res)
				return
		elif err == OK:
			pass
		else:
			return
		yield(get_tree(), "idle_frame")

func _on_LoadFIleBtn_pressed():
	if not filesaver_dialog.visible:
		filesaver_dialog.mode = 0
		filesaver_dialog.popup_centered(Vector2(800, 600))

func _on_NewFileBtn_pressed():
	if not filesaver_dialog.visible:
		filesaver_dialog.mode = 4
		filesaver_dialog.popup_centered(Vector2(800, 600))
		while filesaver_dialog.visible:
			yield(get_tree(), "idle_frame")
		
		if ResourceLoader.exists(active_path):
			switch_to_editor(active_file)

func _on_FileSaver_file_selected(path):
	if filesaver_dialog.mode == 0:
		open_file(path)
	elif filesaver_dialog.mode == 4:
		active_path = path
		save_file(path)

func _on_SaveFileBtn_pressed():
	save_file(active_path)
