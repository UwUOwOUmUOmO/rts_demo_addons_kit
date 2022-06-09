extends Configuration

class_name ChainOfCommand

var host: Node = null

var objectives := []
var immediate_commands := []
var blackboard := {}

func cycle(delta: float):
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
		if not state.has_method("__is_bidding"):
			pass
		elif state.machine_state == 1 and state.yielded_to != name:
			var func_state: GDScriptFunctionState = state.function_state
			state.function_state = null
			if func_state.is_valid(true):
				yield_handler(func_state.resume(), state)
		elif state.machine_state == 2:
			active_array.pop_at(iterator)
			array_size = active_array.size()
			continue
		else:
			if state_ran and not state.coprocess:
				iterator += 1
				continue
			var re = state._cycle(delta, host)
			yield_handler(re, state)
			state_ran = true
		iterator += 1

func yield_handler(return_value, bidding):
	if not return_value is GDScriptFunctionState:
		return return_value
	bidding.machine_state = 1
	bidding.function_state = return_value

func _init():
	exclusion_list.push_back("host")
	._init()
	name = "ChainOfCommand"
	return self

