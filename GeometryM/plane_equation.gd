extends Resource

class_name PlaneEquation

var origin 	:= Vector3.ZERO
var vec1 	:= Vector3.ZERO
var vec2 	:= Vector3.ZERO
var normal 	:= Vector3.ZERO

var a := 0.0
var b := 0.0
var c := 0.0
var d := 0.0

var computed := false

func compute():
	a = normal.x
	b = normal.y
	c = normal.z
	d = -(a * origin.x + b * origin.y + c * origin.z)
	computed = true

func compute_normal():
	normal = Vector3(a, b, c)

func solve(point: Vector3) -> float:
	return (a * point.x) + (b * point.y) + (c * point.z) + d

func distance_to_raw(point: Vector3) -> float:
	if point == Vector3.ZERO:
		print("ERROR: divided by zero, equation: {eq}"\
			.format({"eq": construct()}))
		return 0.0
	var numerator	:= solve(point)
	var denomerator	:= point.length()
	return numerator / denomerator

func distance_to(point: Vector3) -> float:
	return abs(distance_to_raw(point))

func construct() -> String:
	return "{a}x + {b}y + {c}z + {d} = 0"\
		.format({"a": a, "b": b, "c": c, "d": d})
