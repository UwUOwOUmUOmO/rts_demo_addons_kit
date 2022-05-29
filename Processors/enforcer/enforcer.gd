extends Node

class_name ProcessEnforcer

var is_enforced := false
var processor_list := [] setget _set_processor_list, _get_processor_list

func _set_processor_list(procs: Array):
	for c in procs:
		if c is Processor:
			if not c.enforcer_assigned:
				c.enforcer_assigned = true
				processor_list.append(c)

func _get_processor_list():
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
			if proc.terminated:
				processor_list.remove(c)
				r_list.pop_back()
				just_pop = true
				continue
			else:
				_enforce_process(proc, delta, pp)

func run_process_safe(delta: float, pp := false):
	if is_enforced:
		var just_pop := false
		var r_list := range(0, processor_list.size())
		for c in range(0, processor_list.size()):
			if just_pop:
				c -= 1
				just_pop = false
			var proc = processor_list[c]
			if proc is Processor:
				if proc.terminated:
					processor_list.remove(c)
					r_list.pop_back()
					just_pop = true
					continue
				else:
					_enforce_process(proc, delta, pp)
			else:
				processor_list.remove(c)
				r_list.pop_back()
				just_pop = true
				continue

func _enforce_process(proc: Processor, delta: float, pp := false):
	if pp:
		proc._physics_process(delta)
	else:
		proc._process(delta)

func _process(delta):
	run_process_unsafe(delta)

func _physics_process(delta):
	run_process_unsafe(delta, true)

func _exit_tree():
	for p in processor_list:
		if is_instance_valid(p):
			p.enforcer_assigned = false
