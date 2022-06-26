extends Node

var main_package := {}
var temp_package := {}
var prioritize_memory_usage := false

var level_res_override: LevelResource = null # FOR TESTING PURPOSE ONLY

func _init():
#	level_res_override = LevelResource.new()
#	level_res_override.scene = "res://more_test_scenes/test-3.tscn"
#	level_res_override.loading_scene_primary =\
#		preload("res://more_test_scenes/FakeLoadingBar.tscn")
	pass

func debug_code():
	pass

func _ready():
	debug_code()

func c_assets_handler(lv: Level):
	main_package["critical"] = lv.critical_assets
	lv.disconnect("__c_assets_finished", self, "c_assets_handler")

func o_assets_handler(lv: Level):
	main_package["onDemand"] = lv.on_demand_assets
	lv.disconnect("__o_assets_finished", self, "o_assets_handler")
	temp_package = {}

func change_level(path: String, current_level: Level):
	if not prioritize_memory_usage:
		if main_package.empty() and current_level != null:
			main_package["critical"] = current_level.critical_assets
			main_package["onDemand"] = current_level.on_demand_assets
		temp_package = main_package
	main_package = {}
	var err :=  get_tree().change_scene(path)
	if err != OK:
		OutputManager.print_error("Can't instance level: " + path,\
			get_stack())
		return
	var lv: Level = get_tree().current_scene
	if lv == null or not lv is Level:
		OutputManager.print_warning("Current scene is not a level: "\
			+ path, get_stack())
		main_package = temp_package
		temp_package = {}
		return
	else:
		lv.connect("__c_assets_finished", self, "c_assets_handler")
		lv.connect("__o_assets_finished", self, "o_assets_handler")

func change_level_manual(scene: PackedScene):
	get_tree().change_scene_to(scene)
