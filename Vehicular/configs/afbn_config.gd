extends AircraftConfiguration

class_name AFBNewConfiguration

const GRAPH_SIGNALS := {
	"changed": "graph_changes_handler"
}

export(AdvancedCurve) var accel_graph	:= preload("res://addons/Vehicular/configs/stdafbn_accel.tres") \
	setget set_ag
export(AdvancedCurve) var deccel_graph	:= preload("res://addons/Vehicular/configs/stdafbn_deccel.tres") \
	setget set_dg
export(AdvancedCurve) var turn_graph	:= preload("res://addons/Vehicular/configs/stdafbn_turn.tres") \
	setget set_tg
export(float, 0.1, 50.0, 0.1) var turn_rate_amplification := 5.0
export(float, 1.0, 60.0, 0.1) var turn_rate_accu_distipation := 10.0
export(float, 0.01, 1.0, 0.001) var accel_accumulation_lost_rate := 0.4
export(float, 0.01, 1.0, 0.001) var turn_accumulation_lost_rate := 0.4
export(float, 0.1, 1000.0, 0.1) var turn_to_roll_rate := 20.0 * 5.0

#Compatibility values
var max_accel_time := 0.0 setget , get_mat
var max_deccel_time := 0.0 setget , get_mdt
var is_dirty_cache := false setget , get_idc

var cache_mutex_a := Mutex.new()
var cache_mutex_b := Mutex.new()
var cache_mutex_c := Mutex.new()

func get_mat(): return accel_graph.range
func get_mdt(): return deccel_graph.range
func get_idc(): return accel_graph.is_samples_polluted() or deccel_graph.is_samples_polluted() or turn_graph.is_samples_polluted()


func _init():
	name = "AFBNewConfiguration"
	remove_properties(["max_accel_time", "max_deccel_time", "is_dirty_cache", "cache_mutex_a", "cache_mutex_b", "cache_mutex_c"])
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

func set_tg(graph: AdvancedCurve):
	if not is_instance_valid(graph) or graph == turn_graph:
		return
	Utilities.SignalTools.disconnect_from(turn_graph,  self, GRAPH_SIGNALS, false)
	turn_graph = graph
	Utilities.SignalTools.connect_from(turn_graph, self, GRAPH_SIGNALS, false, false)
	graph_changes_handler()

func graph_changes_handler():
	if accel_graph.is_samples_polluted(): 
		cache_mutex_a.lock()
		accel_graph.bake_samples()
		cache_mutex_a.unlock()
	if deccel_graph.is_samples_polluted():
		cache_mutex_b.lock()
		deccel_graph.bake_samples()
		cache_mutex_b.unlock()
	if turn_graph.is_samples_polluted():
		cache_mutex_c.lock()
		turn_graph.bake()
		cache_mutex_c.unlock()

func get_area(from: float, to: float, type: int) -> float:
	match type:
		0: return accel_graph.get_area(from, to)
		1: return deccel_graph.get_area(from, to)
		2: return turn_graph.get_area(from, to)
		_: return 0.0

func get_area_accel(from: float, to: float, _compat = null) -> float:
	return get_area(from, to, 0)

func get_area_deccel(from: float, to: float, _compat = null) -> float:
	return get_area(from, to, 1)

func get_area_turn(from: float, to: float, _compat = null) -> float:
	return get_area(from, to, 2)
