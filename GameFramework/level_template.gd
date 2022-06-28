extends Node

class_name Level

signal __c_assets_finished(lv)
signal __o_assets_finished(lv)
signal __loading_percentage(percent)

onready var LevelSingleton: Node = SingletonManager.fetch("LevelSingleton")

export(String) var level_resource_path := ""

var level_res: LevelResource = null

var loading_scene: Node = null
var main_scene: PackedScene = null

var critical_assets := []
var on_demand_assets := []
var stage1 := false
var stage2 := false
var stop_loading := false


func _ready():
	if LevelSingleton.level_res_override != null:
		level_res = LevelSingleton.level_res_override
		LevelSingleton.level_res_override = null
	setup()

func setup():
	if level_res == null:
		level_res = load(level_resource_path)
		if level_res == null or not level_res is LevelResource:
			Out.print_error("Failed to load level resource",\
				get_stack())
			return
	spawn_loading_scene()
	start_loading()
	while not stage2:
		if stop_loading:
			Out.print_error("Failed to load main scene: " + level_res.scene,\
				get_stack())
			return
		yield(get_tree(), "idle_frame")
	LevelSingleton.main_package["critical"] = critical_assets
	LevelSingleton.main_package["onDemand"] = on_demand_assets
	LevelSingleton.change_level_manual(main_scene)

func spawn_loading_scene():
	if level_res.loading_scene_primary != null:
		loading_scene = level_res.loading_scene_primary.instance()
		add_child(loading_scene)
		if loading_scene.has_method("change_percentage"):
			connect("__loading_percentage", loading_scene, "change_percentage")

func start_loading():
	if not ResourceLoader.exists(level_res.scene):
		stop_loading = true
	var scene_loader := ResourceLoader.load_interactive(level_res.scene)
	var total_stage: int = scene_loader.get_stage_count() + level_res.critical_assets_list.size()
	var current_stage := 0
	var percentage := 0.0
	while true:
		var err = scene_loader.poll()
		if err == ERR_FILE_EOF:
			main_scene = scene_loader.get_resource()
			current_stage = scene_loader.get_stage_count()
			percentage = float(current_stage) / float(total_stage)
			break
		elif err == OK:
			current_stage = scene_loader.get_stage()
			percentage = float(current_stage) / float(total_stage)
			emit_signal("__loading_percentage", percentage)
		else:
			stop_loading = true
			return
		yield(get_tree(), "idle_frame")
	stage1 = true
	var preloader := AssetsPreloader.new()
	var previous_total := current_stage
	preloader.load_assets(level_res.critical_assets_list)
	while preloader.worker_thread.is_alive():
		current_stage = previous_total + preloader.loaded
		percentage = float(current_stage) / float(total_stage)
		emit_signal("__loading_percentage", percentage)
		yield(get_tree(), "idle_frame")
	preloader.worker_thread.wait_to_finish()
	critical_assets = preloader.assets
	stage2 = true

static func get_all_stex(loc := "res://") -> PoolStringArray:
	var list := PoolStringArray()
	var root := Directory.new()
	root.open(loc)
	root.list_dir_begin(true, true)
	while true:
		var file := root.get_next()
		if file.empty():
			break
		var new_loc := loc + file
		if ".stex" in new_loc:
			list.append(new_loc)
		var tmp := Directory.new()
		if tmp.open(new_loc) == OK:
			new_loc += "/"
			list.append_array(get_all_stex(new_loc))
	return list

