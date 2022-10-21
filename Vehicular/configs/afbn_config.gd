extends AircraftConfiguration

class_name AFBNewConfiguration

const GRAPH_SIGNALS := {
	"changed": "graph_changes_handler"
}

export(AdvancedCurve) var accel_graph	:= preload("res://addons/Vehicular/configs/stdafbn_accel.tres") \
	setget set_ag
export(AdvancedCurve) var deccel_graph	:= preload("res://addons/Vehicular/configs/stdafbn_deccel.tres") \
	setget set_dg

#Compatibility values
var max_accel_time := 0.0 setget , get_mat
var max_deccel_time := 0.0 setget , get_mdt

var is_dirty_cache := false setget , get_idc
var cache_mutex := Mutex.new()
var cache_mutex_a := Mutex.new()

func get_mat(): return accel_graph.range
func get_mdt(): return deccel_graph.range
func get_idc(): return accel_graph.is_samples_polluted() or deccel_graph.is_samples_polluted()


func _init():
	name = "AFBNewConfiguration"
	remove_properties(["is_dirty_cache", "cache_mutex", "cache_mutex_a"])
	Utilities.SignalTools.connect_from(accel_graph,  self, GRAPH_SIGNALS, true, false)
	Utilities.SignalTools.connect_from(deccel_graph, self, GRAPH_SIGNALS, true, false)

func set_ag(graph: AdvancedCurve):
	if not is_instance_valid(graph) or graph == accel_graph:
		return
	Utilities.SignalTools.disconnect_from(accel_graph,  self, GRAPH_SIGNALS, false)
	accel_graph = graph
	Utilities.SignalTools.connect_from(accel_graph,  self, GRAPH_SIGNALS, false, false)
	graph_changes_handler()

func set_dg(graph: AdvancedCurve):
	if not is_instance_valid(graph) or graph == deccel_graph:
		return
	Utilities.SignalTools.disconnect_from(deccel_graph,  self, GRAPH_SIGNALS, false)
	deccel_graph = graph
	Utilities.SignalTools.connect_from(deccel_graph, self, GRAPH_SIGNALS, false, false)
	graph_changes_handler()

func graph_changes_handler():
	if accel_graph.is_samples_polluted(): 
		cache_mutex.lock()
		accel_graph.bake_samples()
		cache_mutex.unlock()
	if deccel_graph.is_samples_polluted():
		cache_mutex_a.lock()
		deccel_graph.bake_samples()
		cache_mutex_a.unlock()

func get_area(from: float, to: float, type: int) -> float:
	match type:
		0: return accel_graph.get_area(from, to)
		1: return deccel_graph.get_area(from, to)
		_: return 0.0

func get_area_accel(from: float, to: float, _compat = null) -> float:
	return get_area(from, to, 0)

func get_area_deccel(from: float, to: float, _compat = null) -> float:
	return get_area(from, to, 1)
