extends BTParallel

class_name BTParallellHub

const HUB_SIGNALS := {
	"child_entered_tree": "child_enter_handler",
	"child_exiting_tree": "child_exit_handler",
}

export(bool) var allow_sub_connections := true setget set_asc

var cluster := {}
# var cluster_mutex := Mutex.new()

func _init():
	Utilities.SignalTools.connect_from(self, self, HUB_SIGNALS)

func set_asc(asc: bool):
	allow_sub_connections = asc

func child_enter_handler(node):
	var rel_path := get_path_to(node)
	if allow_sub_connections:
		Utilities.SignalTools.connect_from(node, self, HUB_SIGNALS)
	# cluster_mutex.lock()
	cluster[rel_path as String] = node
	# cluster_mutex.unlock()

func child_exit_handler(node):
	var rel_path := get_path_to(node)
	if allow_sub_connections:
		Utilities.SignalTools.disconnect_from(node, self, HUB_SIGNALS)
	# cluster_mutex.lock()
	cluster.erase(rel_path as String)
	# cluster_mutex.unlock()

# func hub_add(entry: String, node):
# 	if not entry in cluster:
# 		cluster_mutex.lock()
# 		cluster[entry] = node
# 		cluster_mutex.unlock()

# func hub_remove(entry: String):
# 	if entry in cluster:
# 		cluster_mutex.lock()
# 		cluster.erase(entry)
# 		cluster_mutex.unlock()
