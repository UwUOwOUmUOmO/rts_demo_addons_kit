extends ProcessEnforcer

func run_process(delta: float, pp := false):
	run_process_safe(delta, pp)

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
