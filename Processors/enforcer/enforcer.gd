extends Node

class_name ProcessEnforcer

var is_enforced := false
var processor_list := [] setget set_processor_list, get_processor_list

func set_processor_list(proc: Array):
	for c in proc:
		if c is Processor:
			if not c.enforcer_assigned:
				c.enforcer_assigned = true
				processor_list.append(c)
		continue

func get_processor_list():
	return processor_list

# THIS FUNCTION SHOULD ONLY BE CALLED ONCE
func enforce():
	if not is_enforced:
		for c in processor_list:
			if not c is Processor:
				continue
			c._boot()
	is_enforced = true

func run_process_unsafe(delta: float, pp := false):
	if is_enforced:
		var just_pop := false
		var r_list := range(0, processor_list.size())
		for c in range(0, processor_list.size()):
			if just_pop:
				c -= 1
				just_pop = false
			var proc: Processor = processor_list[c]
			if proc.system_shutdown:
				processor_list.remove(c)
				r_list.pop_back()
				just_pop = true
				continue
			else:
				if pp:
					proc._physics_process(delta)
				else:
					proc._process(delta)

func run_process(delta: float, pp := false):
	if is_enforced:
		var just_pop := false
		var r_list := range(0, processor_list.size())
		for c in range(0, processor_list.size()):
			if just_pop:
				c -= 1
				just_pop = false
			var proc = processor_list[c]
			if proc is Processor:
				if proc.system_shutdown:
					processor_list.remove(c)
					r_list.pop_back()
					just_pop = true
					continue
				else:
					if pp:
						proc._physics_process(delta)
					else:
						proc._process(delta)
			else:
				processor_list.remove(c)
				r_list.pop_back()
				just_pop = true
				continue

func _process(delta):
	run_process_unsafe(delta)

func _physics_process(delta):
	run_process_unsafe(delta, true)
