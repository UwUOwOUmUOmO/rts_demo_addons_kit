tool
extends EditorPlugin

class_name GeometryMf

static func pe_create_3p(a: Vector3, b: Vector3, c: Vector3, compute := true)\
	-> PlaneEquation:
	var pe = PlaneEquation.new()
	var v1 = b - a
	var v2 = c - a
	pe.origin = a
	pe.vec1 = v1
	pe.vec2 = v2
	pe.normal = v1.cross(v2)
	if compute:
		pe.compute()
	return pe

static func pe_create_2v(o: Vector3, v1: Vector3, v2: Vector3, compute := true)\
	-> PlaneEquation:
	var pe = PlaneEquation.new()
	pe.origin = o
	pe.vec1 = v1
	pe.vec2 = v2
	pe.normal = v1.cross(v2)
	if compute:
		pe.compute()
	return pe

static func pe_create_2vn(o: Vector3, v1: Vector3, v2: Vector3, nor: Vector3,\
		compute := true)-> PlaneEquation:
	var pe = PlaneEquation.new()
	pe.origin = o
	pe.vec1 = v1
	pe.vec2 = v2
	pe.normal = nor
	if compute:
		pe.compute()
	return pe

static func pe_create_pc(a: float, b: float, c: float, d: float, compute := true)\
	-> PlaneEquation:
	var pe = PlaneEquation.new()
	pe.a = a
	pe.b = b
	pe.c = c
	pe.d = d
	pe.computed = true
	if compute:
		pe.compute_normal()
	return pe

static func le_create_v(v1: Vector3, v2: Vector3) -> LineEquation:
	var le = LineEquation.new()
	le.x0 = v1.x
	le.y0 = v1.y
	le.z0 = v1.z
	le.a  = v2.x
	le.b  = v2.y
	le.c  = v2.z
	return le

static func le_create_p(x0: float, y0: float, z0: float,\
						a: float, b: float, c: float) -> LineEquation:
	var le = LineEquation.new()
	le.x0 = x0
	le.y0 = y0
	le.z0 = z0
	le.a  = a
	le.b  = b
	le.c  = c
	return le

static func point_project(point: Vector3, plane: PlaneEquation) -> Vector3:
	if plane.solve(point) == 0.0:
		return point
	if plane.normal == Vector3.ZERO:
		plane.compute_normal()
	var le = le_create_v(point, plane.normal)
	return le.intersect(plane)

static func mirror(point: Vector3, plane: PlaneEquation) -> Vector3:
	var intersection = point_project(point, plane)
	if plane.normal == Vector3.ZERO:
		plane.compute_normal()
	var v = point - intersection
	var times = v.length()
	return intersection - (plane.normal.normalized() * times)
