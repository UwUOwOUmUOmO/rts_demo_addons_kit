extends ProcessEnforcer

var mutex: Mutex = null
var threads_list := []

func run_process(delta: float, pp := false):
	run_process_safe(delta, pp)

#func run_process_async(delta: float, pp := false):
#	var just_pop := false
#	var r_list := range(0, processor_list.size())
#	for c in range(0, processor_list.size()):
#		if just_pop:
#			c -= 1
#			just_pop = false
#		var proc = processor_list[c]
#		if proc is Processor:
#			if proc.terminated:
#				processor_list.remove(c)
#				r_list.pop_back()
#				just_pop = true
#				continue
#			else:
#				var thread := Thread.new()
#				thread.start(self, "_enforce_process", [proc, delta, pp])
#				threads_list.append(thread)
#		else:
#			processor_list.remove(c)
#			r_list.pop_back()
#			just_pop = true
#	for t in threads_list:
#		var thread: Thread = t
#		if thread.is_alive():
#			yield(get_tree(), "idle_frame")
#		else:
#			thread.wait_to_finish()
#	threads_list = []

func _set_processor_list(procs: Array):
	for c in procs:
		if c is Processor:
			if not c.enforcer_assigned:
				c.enforcer_assigned = true
				c._boot()
				processor_list.append(c)

func add_processor(proc: Processor):
	if not proc.enforcer_assigned:
		proc.enforcer_assigned = true
		proc._boot()
		processor_list.append(proc)

func _ready():
	enforce()

func _process(delta):
	run_process(delta)

func _physics_process(delta):
	run_process(delta, true)
