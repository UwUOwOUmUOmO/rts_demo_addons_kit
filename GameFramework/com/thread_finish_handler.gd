extends Reference

class_name ThreadFinishHandler

func end_thread(thread: Thread, tree: SceneTree):
	var t := thread
	while t.is_active():
		yield(tree, "idle_frame")
	return t.wait_to_finish()
