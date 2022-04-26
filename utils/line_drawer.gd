extends ImmediateGeometry

export(Array) var paths = [Vector3.ZERO]
export(Material) var pathsMaterial = SpatialMaterial.new()

func _ready():
	drawPath()

func drawPath():
	if paths.size() <= 1:
		return
	set_material_override(pathsMaterial)
	clear()
	begin(Mesh.PRIMITIVE_POINTS, null)
	add_vertex(paths[0])
	add_vertex(paths[paths.size() - 1])
	end()
	begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for x in paths:
		add_vertex(x)
	end()
