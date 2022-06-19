extends Processor

class_name ChainOfCommand

# Volatile
var activated := false

# Persistent
var objectives := []
var immediate_commands := []
var blackboard := {}

func _set_host(h):
	._set_host(h)
	activated = true

func _compute(delta: float):
	# If the Command Chain has been activated then check if the host is a valid
	# instance, if not then automatically terminate then Processor
	# If the Command Chain has not been activated then return
	if activated:
		if not is_instance_valid(host):
			terminated = true
			return
	else:
		return
	main_cycle(delta, 0)
	main_cycle(delta, 1)

func main_cycle(delta: float, active := 0):
	var active_array := []
	match active:
		0:
			active_array = objectives
		1:
			active_array = immediate_commands
		_:
			return
	var state_ran := false
	var iterator := 0
	var array_size := active_array.size()
	var state
	while iterator < array_size:
		state = active_array[iterator]
		# If not a Bidding, increment the iterator and continue
		if not state.has_method("__is_bidding"):
			pass
		# If previous Bidding yielded to other entity (yielded_to is self-set),
		# resume the function state
		# Increment the iterator and continue
		elif state.machine_state == 1 and state.yielded_to != name:
			var func_state: GDScriptFunctionState = state.function_state
			state.function_state = null
			if func_state.is_valid(true):
				yield_handler(func_state.resume(), state)
		# If the Bidding has expired (self-set), remove it from the array
		# Do not increment the iterator
		elif state.machine_state == 2:
			active_array.pop_at(iterator)
			array_size = active_array.size()
			continue
		# If nothing out of ordinary, run the Bidding's main process
		# Increment the iterator and continue
		else:
			# If no state was ran then run the current state
			# If any state was ran, check if the current one is a coprocess
			# If yes, run the current state
			# If not, increment the iterator and continue
			if state_ran and not state.coprocess:
				iterator += 1
				continue
			var re = state._cycle(delta, host)
			yield_handler(re, state)
			state_ran = true
		iterator += 1

func yield_handler(return_value, bidding):
	# If the return value is not a GDScriptFuntionState, return it
	# Else set the machine state to Running and set function_state
	if not return_value is GDScriptFunctionState:
		return return_value
	bidding.machine_state = 1
	bidding.function_state = return_value

func _init():
	exclusion_list.push_back("activated")
	._init()
	name = "ChainOfCommand"
	return self

