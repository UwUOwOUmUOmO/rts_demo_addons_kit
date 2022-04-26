extends Spatial

export(float) var speed = 10.0

func _process(delta):
	rotate_y(speed * delta)
