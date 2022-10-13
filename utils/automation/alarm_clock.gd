extends Reference

class_name AlarmClock

func setup(tree: SceneTree, timeout: float,\
		base_class, method: String, params := []):
	if timeout <= 0.0:
		yield(tree, "idle_frame")
	else:
		yield(Out.timer(timeout), "timeout")
	var ref := funcref(base_class, method)
	ref.call_funcv(params)
