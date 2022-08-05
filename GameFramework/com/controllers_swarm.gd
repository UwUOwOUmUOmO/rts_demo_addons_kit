extends Node

func clean_defered(con: Node, duration: float):
	yield(get_tree().create_timer(duration, false), "timeout")
	con.queue_free()

func add_peripheral(con: Node, auto_clean := -1.0):
	call_deferred("add_child", con)
	if auto_clean > 0.0:
		clean_defered(con, auto_clean)
	while not is_instance_valid(con.get_parent()):
		yield(get_tree(), "idle_frame")
	if con.has_method("on_peripherals_pool_entered"):
		con.on_peripherals_pool_entered(self)
