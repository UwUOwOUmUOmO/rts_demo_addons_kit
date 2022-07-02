extends Reference

class_name AssetsPreloader

signal __finished_loading(preloader)

var tree: SceneTree = null
var assets := []
var total_assets := 0
var loaded := 0
var finished_loading := false

func _init(scene_tree: SceneTree):
	tree = scene_tree
	connect("__finished_loading", self, "finished_handler")

func worker(list: PoolStringArray):
	assets.resize(total_assets)
	loaded = 0
	for item in list:
		var res = load(item)
		if res == null:
			Out.print_warning("Failed to load resource at: {loc}"\
				.format({"loc": item}), get_stack())
		assets[loaded] = res
		loaded += 1
	loaded = total_assets
	emit_signal("__finished_loading", self)

func load_assets(target_list: PoolStringArray):
	finished_loading = false
	total_assets = target_list.size()
	load_deferred(target_list)

func load_deferred(list: PoolStringArray):
	assets.resize(total_assets)
	loaded = 0
	yield(tree, "idle_frame")
	for item in list:
		var res = load(item)
		if res == null:
			Out.print_warning("Failed to load resource at: {loc}"\
				.format({"loc": item}), get_stack())
		assets[loaded] = res
		loaded += 1
		
	loaded = total_assets
	emit_signal("__finished_loading", self)

func get_percentage() -> float:
	if total_assets == 0:
		return 0.0
	else:
		var perc := float(loaded) / float(total_assets)
		return perc

func finished_handler(_preloader):
	finished_loading = true
