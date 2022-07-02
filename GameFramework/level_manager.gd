extends Node

var preloaded := []
var curr_lmac: LM_AssistClass = null

class LM_AssistClass extends Reference:
	signal __finished_all()
	signal __loading_percentage(percent)
	signal __lmac_finished()

	var lspc: AssetsPreloader = null
	var mpc: AssetsPreloader = null
	var tree: SceneTree = null
	var loading_scene = null
	var main_scene_packed = null

	var ls_status := false
	var main_status := false

	var current_main_stage := 0
	var current_pl_stage := 0
	var total_stages := 0

	func _init(t: SceneTree):
		tree = t
		connect("__finished_all", self, "load_main_finished_handler")

	static func defer_loading_scene(path: String) -> AssetsPreloader:
		var preload_com := AssetsPreloader.new()
		preload_com.load_assets([path])
		return preload_com

	func spawn_loading_scene(path: String):
		if not ResourceLoader.exists(path):
			Out.print_warning("Loading scene not exists: " + path, \
				get_stack())
			ls_status = true
			return
		lspc = defer_loading_scene(path)
		lspc.connect("__finished_loading", self, "loading_scene_finished_loading")

	func loading_scene_finished_loading(preloader):
		ThreadFinishHandler.new().end_thread(preloader.worker_thread, tree)
		loading_scene = preloader.assets[0].instance()
		tree.current_scene.add_child(loading_scene)
		if loading_scene.has_method("change_percentage"):
		   connect("__loading_percentage", loading_scene, "change_percentage")
		ls_status = true

	func load_main(scene_path: String, p_list: PoolStringArray):
		if not ResourceLoader.exists(scene_path):
			Out.print_error("Main scene not exists: " + scene_path, \
				get_stack())
			main_status = true
			return
		while not ls_status:
			yield(tree, "idle_frame")
		mpc = AssetsPreloader.new()
		mpc.connect("__finished_loading", self, "mpc_finished_handler")
		var load_inter := ResourceLoader.load_interactive(scene_path, "PackedScene")
		total_stages += load_inter.get_stage_count()
		total_stages += p_list.size()
		mpc.load_assets(p_list)
		main_handler(load_inter)
		preload_handler(mpc)
		percentage_handler()

	func mpc_finished_handler(preloader):
		ThreadFinishHandler.new().end_thread(preloader.worker_thread, tree)

	func percentage_handler():
		while not main_status:
			var percent: float = float(current_main_stage + current_pl_stage) / float(total_stages)
			emit_signal("__loading_percentage", percent)
			if main_scene_packed != null and mpc.finished_loading:
				if loading_scene != null:
					var l_parent = loading_scene.get_parent()
					if is_instance_valid(l_parent):
						l_parent.remove_child(loading_scene)
					loading_scene.queue_free()
				tree.change_scene_to(main_scene_packed)
				emit_signal("__finished_all")
				break
			yield(tree, "idle_frame")

	func main_handler(load_inter: ResourceInteractiveLoader):
		while true:
			var err := load_inter.poll()
			if err == OK:
				current_main_stage = load_inter.get_stage()
			elif err == ERR_FILE_EOF:
				main_scene_packed = load_inter.get_resource()
				current_main_stage = load_inter.get_stage_count()
			else:
				break
			yield(tree, "idle_frame")

	func preload_handler(preloader: AssetsPreloader):
		while not preloader.finished_loading:
			current_pl_stage = preloader.loaded
			yield(tree, "idle_frame")

	func load_main_finished_handler():
		var lvl_mgr = SingletonManager.fetch("LevelManager")
		lvl_mgr.preloaded = mpc.assets
		main_status = true
		emit_signal("__lmac_finished")

func load_level(cfg: LevelConfiguration, wait := false) -> bool:
	while curr_lmac != null:
		if wait:
			yield(get_tree(), "idle_frame")
		else:
			Out.print_warning("A different level is currently being loaded", \
				get_stack())
			return false
	curr_lmac = LM_AssistClass.new(get_tree())
	curr_lmac.spawn_loading_scene(cfg.loading_scene_path)
	curr_lmac.load_main(cfg.scene_path, cfg.preload_list)
	curr_lmac.connect("__lmac_finished", self, "lmac_finish_handler")
	return true

func manual_change_scene(to: PackedScene):
	get_tree().change_scene_to(to)

func lmac_finish_handler():
	curr_lmac.disconnect("__lmac_finished", self, "lmac_finish_handler")
	curr_lmac = null
