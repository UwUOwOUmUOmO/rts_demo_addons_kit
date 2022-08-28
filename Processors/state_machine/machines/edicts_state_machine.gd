extends StateMachine

class_name EdictsStateMachine

signal __edicts_refetch(edict)

# Volatile
var director = null setget set_director

func _init():
	name = "EdictsStateMachine"
	remove_properties(["director"])
	is_paused = true

func set_director(d):
	director = d
	Utilities.SignalTools.connect_from(director, self, \
		WorkerStateMachine.WSM_SIGNALS, true, false)

func edicts_refetch_handler(e):
	emit_signal("__edicts_refetch", e)

func get_edicts_chain() -> Dictionary:
	var my_edict := states_pool
	var upper_edicts: Dictionary = Utilities.TrialTools.try_call(director, \
		"get_edicts_chain", [], {})
	upper_edicts.merge(my_edict)
	return upper_edicts

func add_state(s: StateSingular):
	if s is Edicts:
		if s.force_edicts_refetch: emit_signal("__edicts_refetch", s)
		.add_state(s)

func add_state_prioritized(s: StateSingular):
	if s is Edicts:
		if s.force_edicts_refetch: emit_signal("__edicts_refetch", s)
		.add_state_prioritized(s)

func insert_state(s: StateSingular, after: String):
	if s is Edicts:
		if s.force_edicts_refetch: emit_signal("__edicts_refetch", s)
		.insert_state(s, after)

# func clear_states_pool():
# 	sp_mutex.lock()
# 	states_pool = {first_state.state_name: first_state}
# 	yield_pool  = {first_state.state_name: null}
# 	last_state  = first_state
# 	processing_state = null
# 	current_size = 1
# 	sp_mutex.unlock()

# func remove_state_by_id(id: int):
# 	if id == 0:
# 		return
# 	.remove_state_by_id(id)

# func pop_front():
# 	sp_mutex.lock()
# 	if current_size > 1:
# 		states_pool.erase(states_pool.keys()[1])
# 		yield_pool.erase(yield_pool.keys()[1])
# 		current_size -= 1
# 		last_state = states_pool[states_pool.keys().back()]
# 	sp_mutex.unlock()

# func pop_back():
# 	if current_size <= 1:
# 		return
# 	sp_mutex.lock()
# 	states_pool.erase(states_pool.keys().back())
# 	yield_pool.erase(yield_pool.keys().back())
# 	current_size -= 1
# 	if states_pool.empty():
# 		first_state = null
# 		processing_state = null
# 	else:
# 		states_pool[states_pool.keys().back()].next_state = null
# 	last_state = states_pool[states_pool.keys().back()]
# 	sp_mutex.unlock()
