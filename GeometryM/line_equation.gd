extends Resource

class_name LineEquation

var x0 := 0.0
var y0 := 0.0
var z0 := 0.0

var a := 0.0
var b := 0.0
var c := 0.0

func find_parameter(pe: PlaneEquation):
	var param: float
	
	var sec1: float = pe.a * x0
	var sec2: float = pe.b * y0
	var sec3: float = pe.c * z0
	
	var pnum: float = (pe.a * a) + (pe.b * b) + (pe.c * c)
	var rnum: float = -(sec1 + sec2 + sec3 + pe.d)
	
	if pnum == 0.0:
		printerr("ERROR: divided by zero, equation: {eq}"\
			.format({"eq": construct()}))
		return null
	
	param = rnum / pnum
	return param

func solve(param: float) -> Vector3:
	var final := Vector3.ZERO
	final.x = param * a + x0
	final.y = param * b + y0
	final.z = param * c + z0
	return final

func intersect(pe: PlaneEquation) -> Vector3:
	var param = find_parameter(pe)
	if param == null:
		return Vector3.ZERO
	return solve(find_parameter(pe))

func construct():
	return "(x, y, z) = ({x0}, {y0}, {z0}) + t({a}, {b}, {c})"\
		.format({"x0": x0, "y0": y0, "z0": z0,
				 "a": a, "b": b, "c": c})
