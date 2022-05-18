extends Spatial

export(PoolRealArray) var distance_interpolation = [0]

var children := []
var sorted_children := []
var distances_squared: PoolRealArray = []

func bake(sort_list := true):
	children = get_children()
	distances_squared.resize(0)
	for d in distance_interpolation:
		distances_squared.append(d * d)
	if sort_list:
		sort()

func sort():
	sorted_children.clear()
	sorted_children.resize(children.size())
	for c in children:
		if not c is Spatial:
			continue
		var name: String = c.name
		if name.begins_with("LOD"):
			var level: String = name
			level.erase(0, 3)
			var level_int := level.to_int()
			if level_int + 1 > children.size():
				continue
			sorted_children[level_int] = c
		else:
			continue

func _ready():
	bake()

func _process(delta):
	if sorted_children.size() == 0:
		return
	var camera := get_viewport().get_camera()
	if camera == null:
		return
	var distance_squared := camera.global_transform.origin.\
		distance_squared_to(global_transform.origin)
	var level := 0
	for d in distances_squared:
		if distance_squared < d:
			if level > 0:
				level -= 1
			break
		else:
			level += 1
	if level + 1 > sorted_children.size():
		level = sorted_children.size() - 1
	for c in range(0, sorted_children.size()):
		sorted_children[c].visible = (level == c)
