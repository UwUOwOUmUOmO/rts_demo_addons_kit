extends Reference

class_name AssetsPreloader

signal __finished_loading(preloader)

var assets := []
var worker_thread: Thread = null
var total_assets := 0
var loaded := 0
var finished_loading := false

func _init():
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
	total_assets = target_list.size()
	worker_thread = Thread.new()
	var err := worker_thread.start(self, "worker", target_list)
	if err == ERR_CANT_CREATE:
		Out.print_error("Can't create worker thread",\
			get_stack())
#	worker(target_list)

func get_percentage() -> float:
	if total_assets == 0:
		return 0.0
	else:
		var perc := float(loaded) / float(total_assets)
		return perc

func finished_handler(_preloader):
	worker_thread.wait_to_finish()
	finished_loading = true
