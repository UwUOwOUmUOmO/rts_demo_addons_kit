extends Reference

var objects := []

func destruct(time: float, scene: SceneTree, force_free := false):
	yield(scene.create_timer(time), "timeout")
	for c in objects:
		if force_free:
			c.free()
		else:
			c.queue_free()
