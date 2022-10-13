extends AircraftConfiguration

class_name AFBConfiguration

const INTEGRAL_SAMPLES := 64
const GRAPH_SIGNALS := {
	"changed": "graph_changes_handler"
}

# Persistent
export(float, 0.1, 20.0)	var max_accel_time			:= 5.0
export(float, 0.1, 20.0)	var max_deccel_time			:= 5.0
export(int, 10, 1000)		var graph_bake_resolution	:= 600 setget set_gbr
export(bool) 				var use_integral_sampling	:= false
export(bool)				var allow_benchmark			:= false
export(Curve)				var accel_graph				:= preload("res://addons/Vehicular/configs/stdafb_accel.res")\
	setget set_ag
export(Curve)				var deccel_graph			:= preload("res://addons/Vehicular/configs/stdafb_deccel.res")\
	setget set_dg

# Volatile
var agg_baked_data	: PoolRealArray = []
var dgg_baked_data	: PoolRealArray = []
var is_dirty_cache	:= true
var cache_mutex		:= Mutex.new()

func _init():
	name = "AFBConfiguration"
	remove_properties(["agg_baked_data", "dgg_baked_data", "is_dirty_cache", "cache_mutex"])
	Utilities.SignalTools.connect_from(accel_graph,  self, GRAPH_SIGNALS, true, false)
	Utilities.SignalTools.connect_from(deccel_graph, self, GRAPH_SIGNALS, true, false)

func set_gbr(res: int):
	graph_bake_resolution = res
	flag_dirty_cache()

func set_ag(graph: Curve):
	if not is_instance_valid(graph) or graph == accel_graph:
		return
	Utilities.SignalTools.disconnect_from(accel_graph,  self, GRAPH_SIGNALS, false)
	accel_graph = graph
	Utilities.SignalTools.connect_from(accel_graph,  self, GRAPH_SIGNALS, false, false)
	flag_dirty_cache()

func set_dg(graph: Curve):
	if not is_instance_valid(graph) or graph == deccel_graph:
		return
	Utilities.SignalTools.disconnect_from(deccel_graph,  self, GRAPH_SIGNALS, false)
	deccel_graph = graph
	Utilities.SignalTools.connect_from(deccel_graph, self, GRAPH_SIGNALS, false, false)
	flag_dirty_cache()

func graph_changes_handler():
	flag_dirty_cache()

func flag_dirty_cache():
	cache_mutex.lock()
	is_dirty_cache = true
	cache_mutex.unlock()

func sample_val(stamp: float, type := 0) -> float:
	#   --TYPES:
	# 0: Acceleration
	# 1: Decceleration
	match type:
		0:
			var perc := clamp(stamp / max_accel_time, 0.0, 1.0)
			return accel_graph.interpolate_baked(perc)
		1:
			var perc := clamp(stamp / max_deccel_time, 0.0, 1.0)
			return deccel_graph.interpolate_baked(perc)
		_:
			return 0.0

func bake_graph():
#	Out.print_debug("Bake called", get_stack())
	agg_baked_data = []
	agg_baked_data.resize(graph_bake_resolution)
	dgg_baked_data = []
	dgg_baked_data.resize(graph_bake_resolution)
	var graph_length   := 0.0
	var accel_length   := 0.0
	var deccel_length  := 0.0
	var graph_loc_prev := 0.0
	var graph_loc_curr := 0.0
	var garph_loc_increment := 1.0 / graph_bake_resolution
	for iter in range(1, graph_bake_resolution):
		graph_loc_curr += garph_loc_increment
		if iter == 1:
			graph_length	  = graph_loc_curr - graph_loc_prev
			accel_length	  = max_accel_time * graph_length
			deccel_length	  = max_deccel_time * graph_length
			agg_baked_data[0] = accel_graph.interpolate_baked(0.0) * accel_length
			dgg_baked_data[0] = deccel_graph.interpolate_baked(0.0) * deccel_length
		var accel_height	 := accel_graph.interpolate_baked(graph_loc_curr)
		var deccel_height	 := deccel_graph.interpolate_baked(graph_loc_curr)
		agg_baked_data[iter]  = (accel_height * accel_length) + agg_baked_data[iter - 1]
		dgg_baked_data[iter]  = (deccel_height * deccel_length) + dgg_baked_data[iter - 1]
		graph_loc_prev = graph_loc_curr
	is_dirty_cache = false

func fetch_graph_area(from: float, to: float, type: int) -> float:
	cache_mutex.lock()
	if is_dirty_cache:
		bake_graph()
	cache_mutex.unlock()
	match type:
		0:
			var floc := (from / max_accel_time) * graph_bake_resolution
			var tloc := (to / max_accel_time) * graph_bake_resolution
			var prev := agg_baked_data[clamp(int(floc), 0, graph_bake_resolution - 1)]
			var curr := agg_baked_data[clamp(int(tloc), 0, graph_bake_resolution - 1)]
			return curr - prev
		1:
			var floc := (from / max_deccel_time) * graph_bake_resolution
			var tloc := (to / max_deccel_time) * graph_bake_resolution
			var prev := dgg_baked_data[clamp(int(floc), 0, graph_bake_resolution - 1)]
			var curr := dgg_baked_data[clamp(int(tloc), 0, graph_bake_resolution - 1)]
			return curr - prev
		_:
			return 0.0

func get_area(from: float, to: float, max_sample: int, type: int, integral_sampling: bool) -> float:
	#   --TYPES:
	# 0: Acceleration
	# 1: Decceleration
	var start := Time.get_ticks_usec()
	var pfrom := 0.0
	var pto := 0.0
	var graph := accel_graph
	var max_time := max_accel_time
	match type:
		0:
			# pfrom = clamp(from / max_accel_time, 0.0, 1.0)
			# pto = clamp(to / max_accel_time, 0.0, 1.0)
			pfrom = from / max_accel_time
			pto = to / max_accel_time
			pto = max(pfrom, pto)
		1:
			# pfrom = clamp(from / max_deccel_time, 0.0, 1.0)
			# pto = clamp(to / max_deccel_time, 0.0, 1.0)
			pfrom = from / max_deccel_time
			pto = to / max_deccel_time
			pto = max(pfrom, pto)
			graph = deccel_graph
			max_time = max_deccel_time
		_:
			return 0.0
	if pfrom == pto:
		return 0.0
	# --------------------------------
	var area := 0.0
	if pfrom < 0.0:
		var length := 0.0 - from
		area += graph.min_value * length
		pfrom = 0.0
	elif pfrom > 1.0:
		var length := from - max_time
		area -= graph.max_value * length
		pfrom = 1.0
	if pto > 1.0:
		var length := to - max_time
		area += graph.max_value * length
		pto = 1.0
	elif pto < 0.0:
		var length := 0.0 - to
		area -= graph.min_value * length
		pto = 0.0
	if pfrom == pto:
		return area
	if not integral_sampling:
		area += fetch_graph_area(from, to, type)
	else:
		var delta  := (pto - pfrom) / max_sample
		var real_value_delta := (to - from) / max_sample
		var seeker := pfrom
		# ------------ SAMPLE ------------
		var iter := 0
		while true:
			area += graph.interpolate_baked(seeker) * real_value_delta
			seeker += delta
			iter += 1
			if not (iter < max_sample - 1):
				break
		# --------------------------------
	if allow_benchmark:
		var end := Time.get_ticks_usec()
		Out.print_debug("Integral performance: {t} usec(s) | Integral sampling: {is}"\
			.format({"t": end - start, "is": integral_sampling}))
	return area

func sample_accel(time_stamp: float) -> float:
	return sample_val(time_stamp, 0)

func sample_deccel(time_stamp: float) -> float:
	return sample_val(time_stamp, 1)

func get_area_accel(from: float, to: float, samples := INTEGRAL_SAMPLES, integral_sampling := use_integral_sampling) -> float:
	return get_area(from, to, samples, 0, integral_sampling)

func get_area_deccel(from: float, to: float, samples := INTEGRAL_SAMPLES, integral_sampling := use_integral_sampling) -> float:
	return get_area(from, to, samples, 1, integral_sampling)
