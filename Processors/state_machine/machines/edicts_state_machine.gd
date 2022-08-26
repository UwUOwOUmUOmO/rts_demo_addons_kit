extends StateMachine

class_name EdictsStateMachine

func _init():
	name = "EdictsStateMachine"
	var idle_state := EdictIdle.new()
	add_state(idle_state)

func add_state_prioritized(s: StateSingular):
	insert_state(s, "Idle")

func clear_states_pool():
	sp_mutex.lock()
	states_pool = {first_state.state_name: first_state}
	yield_pool  = {first_state.state_name: null}
	last_state  = first_state
	processing_state = null
	current_size = 1
	sp_mutex.unlock()

func remove_state_by_id(id: int):
	if id == 0:
		return
	.remove_state_by_id(id)

func pop_front():
	sp_mutex.lock()
	if current_size > 1:
		states_pool.erase(states_pool.keys()[1])
		yield_pool.erase(yield_pool.keys()[1])
		current_size -= 1
		last_state = states_pool[states_pool.keys().back()]
	sp_mutex.unlock()

func pop_back():
	if current_size <= 1:
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
