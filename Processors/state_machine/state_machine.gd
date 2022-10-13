extends Processor

class_name StateMachine

const MAX_STACK := 64
const DEFAULT_MAX_ALLOWED_EXECUTION_TIME := 1000.0

signal __state_added(machine, state_name, state_reference)
signal __state_removed(machine, state_name, state_reference)

# Persistent
var states_pool := {}
var yield_pool := {}
var blackboard := {}
var current_size := 0
var max_alloted_time := DEFAULT_MAX_ALLOWED_EXECUTION_TIME
var is_paused := false

# Volatile
var sp_mutex := Mutex.new()
var bb_mutex := Mutex.new()
var first_state: StateSingular = null
var last_state: StateSingular  = null
var processing_state: StateSingular = null

func _init():
	name = "StateMachine"
	remove_properties(["sp_mutex", "bb_mutex", "first_state"])

func _object_deserialized():
	sp_mutex.lock()
	var keys_list := states_pool.keys()
	first_state = states_pool[keys_list.front()]
	for key in yield_pool:
		yield_pool[key] = null
	for iter in range(0, states_pool.size()):
		var next = null
		if iter < states_pool.size() - 1:
			next = states_pool[keys_list[iter + 1]]
		states_pool[keys_list[iter]].next_state = next
	sp_mutex.unlock()

func _termination_handler(_proc):
	is_paused = true
	sp_mutex = null
	bb_mutex = null
	states_pool = {}
	yield_pool = {}
	blackboard = {}
	first_state = null
	last_state = null
	processing_state = null

func state_check(s: StateSingular):
	var s_name := s.state_name
	return not s_name in states_pool and \
		not s_name.empty() and s.current_machine == null

func mass_push(states: Array):
	for s in states:
		add_state(s)

func add_state(s: StateSingular) -> void:
	var s_name := s.state_name
	sp_mutex.lock()
	if state_check(s):
		states_pool[s_name] = s
		yield_pool[s_name] = null
		current_size += 1
		if current_size == 1:
			first_state = s
		elif current_size > 1:
			var prev = states_pool[states_pool.keys()[current_size - 2]]
			prev.next_state = s
		last_state = s
		Utilities.SignalTools.connect_from(self, s, StateSingular.STATE_SINGULAR_SIGNALS)
		emit_signal("__state_added", self, s_name, s)
	sp_mutex.unlock()

func add_state_prioritized(s: StateSingular):
	var s_name := s.state_name
	sp_mutex.lock()
	if current_size == 0:
		sp_mutex.unlock()
		return add_state(s)
	if state_check(s):
		var new_states_pool := {s_name: s}
		var new_yield_pool 	:= {s_name: null}
		new_states_pool.merge(states_pool)
		new_yield_pool.merge(yield_pool)
		states_pool = new_states_pool
		yield_pool = new_yield_pool
		current_size += 1
		var old_first_state := first_state
		first_state = s
		s.next_state = old_first_state
		last_state = states_pool[states_pool.keys().back()]
		Utilities.SignalTools.connect_from(self, s, StateSingular.STATE_SINGULAR_SIGNALS)
		emit_signal("__state_added", self, s_name, s)
	sp_mutex.unlock()

func get_state_priority(s: StateSingular) -> int:
	if not state_check(s):
		return -1
	return states_pool.keys().find(s.state_name)

func insert_state(s: StateSingular, after: String):
	var s_name := s.state_name
	if not after in states_pool or not state_check(s):
		return
	sp_mutex.lock()
	var new_states_pool := {}
	var new_yield_pool := {}
	for key in states_pool:
		var value = states_pool[key]
		new_states_pool[key] = value
		new_yield_pool[key] = null
		if key == after:
			s.next_state = value.next_state
			value.next_state = s
			new_states_pool[s_name] = s
			new_yield_pool[s_name] = null
	states_pool = new_states_pool
	yield_pool = new_yield_pool
	current_size += 1
	last_state = states_pool[states_pool.keys().back()]
	Utilities.SignalTools.connect_from(self, s, StateSingular.STATE_SINGULAR_SIGNALS)
	emit_signal("__state_added", self, s_name, s)
	sp_mutex.unlock()

func clear_states_pool():
	sp_mutex.lock()
	states_pool = {}
	yield_pool = {}
	first_state = null
	last_state = null
	processing_state = null
	current_size = 0
	sp_mutex.unlock()

func remove_state_by_id(id: int):
	if id < 0 or id >= current_size:
		return
	sp_mutex.lock()
	var removed_id := id
	var s_name: String= states_pool.keys()[removed_id]
	var state_ref = states_pool[s_name]
	states_pool.erase(s_name)
	yield_pool.erase(s_name)
	# --------------------------------------------------
	current_size -= 1
	if removed_id == 0:
		first_state = states_pool[states_pool.keys().front()]
	else:
		var before_state = states_pool[states_pool.keys()[removed_id - 1]]
		var after_state
		if removed_id >= current_size:
			after_state = null
		else:
			after_state = states_pool[states_pool.keys()[removed_id]]
		before_state.next_state = after_state
	# --------------------------------------------------
	if current_size > 0:
		last_state = states_pool[states_pool.keys().back()]
	else:
		last_state = null
	emit_signal("__state_removed", self, s_name, state_ref)
	sp_mutex.unlock()

func remove_state_by_name(s_name: String):
	var removed_id := states_pool.keys().find(s_name)
	remove_state_by_id(removed_id)

func remove_state(s):
	var s_name := ""
	if s is String:
		s_name = s
	elif s is StateSingular:
		s_name = s.state_name
	elif s is int:
		remove_state_by_id(s)
		return
	remove_state_by_name(s_name)

func pop_front():
	if states_pool.empty():
		return
	sp_mutex.lock()
	states_pool.erase(states_pool.keys().front())
	yield_pool.erase(yield_pool.keys().front())
	current_size -= 1
	if states_pool.empty():
		first_state = null
		processing_state = null
		last_state = null
	else:
		first_state = states_pool.keys().front()
		last_state = states_pool[states_pool.keys().back()]
	sp_mutex.unlock()

func pop_back():
	if states_pool.empty():
		return
	sp_mutex.lock()
	states_pool.erase(states_pool.keys().back())
	yield_pool.erase(yield_pool.keys().back())
	current_size -= 1
	if states_pool.empty():
		first_state = null
		processing_state = null
	else:
		states_pool[states_pool.keys().back()].next_state = null
		last_state = states_pool[states_pool.keys().back()]
	sp_mutex.unlock()

func get_front() -> StateSingular:
	return first_state

func get_back() -> StateSingular:
	return last_state

func blackboard_set(index: String, value):
	bb_mutex.lock()
	blackboard[index] = value
	bb_mutex.unlock()

func blackboard_get(index: String):
	return blackboard.get(index)

func _compute(delta: float):
	var stack_count := 0
	var epoch := Time.get_ticks_usec()
	var delta_time := 0.0
	while processing_state != null and not terminated and not is_paused:
		if stack_count >= MAX_STACK:
			processing_state = first_state
			break
		var last_yield = yield_pool.get(processing_state.state_name)
		var re = null
		if last_yield is GDScriptFunctionState:
			if last_yield.is_valid():
				# Function is suspended, do not proceed further
				re = last_yield
			else:
				re = null
		elif not processing_state.suspended:
			re = processing_state._compute(delta)
		sp_mutex.lock()
		if yield_pool.has(processing_state.state_name):
			yield_pool[processing_state.state_name] = re
		processing_state = processing_state.next_state
		sp_mutex.unlock()
		stack_count += 1
		# -------------------------------------------
		var next_epoch := Time.get_ticks_usec()
		delta_time = next_epoch - epoch
		if delta_time > max_alloted_time:
			break
	if processing_state == null:
		sp_mutex.lock()
		processing_state = first_state
		sp_mutex.unlock()
