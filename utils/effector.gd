extends Configuration

class_name Effector

enum CHARTABLE_DATA { INVALID, AUTO, INT, FLOAT, VECTOR2, VECTOR3 }

# Persistent
var course: Curve	   = null
var type: int		   = CHARTABLE_DATA.AUTO

func _init(c := "", t: int = CHARTABLE_DATA.AUTO):
	
	if not c.empty():
		course = ResourceLoader.load(c, "Curve")
	type = t
	return self

func type_deduce(data) -> int:
	var t: int = CHARTABLE_DATA.INVALID
	if data is int:
		t = CHARTABLE_DATA.INT
	elif data is float:
		t = CHARTABLE_DATA.FLOAT
	elif data is Vector2:
		t = CHARTABLE_DATA.VECTOR2
	elif data is Vector3:
		t = CHARTABLE_DATA.VECTOR3
	return type

func is_chartable(t: int) -> bool:
	if type == CHARTABLE_DATA.AUTO:
		return true
	elif type == CHARTABLE_DATA.FLOAT and t == CHARTABLE_DATA.INT:
		return true
	else:
		return type == t

func is_ready() -> bool:
	return not course == null

func chart_value(s, f, w):
	var re
	# Normalize the course
	var maxval: float= course.max_value
	var minval: float = course.min_value

	var lerp_result := course.interpolate(w)

	# Revert the course to its original state
	course.max_value = maxval
	course.min_value = minval

	re = ((f - s) * w) + s

	return re

func chart(weight, start = 0, fin = 0):
	if not is_ready():
		Out.print_error("Effector missing a course",\
			get_stack())
		return null
	# DEFAULT
	elif start == fin:
		return course.interpolate(weight)
	var current_type: int = type_deduce(start)
	if not is_chartable(current_type) or\
		current_type == CHARTABLE_DATA.INVALID:
			Out.print_error("Data is not chartable", \
				get_stack())
			return null
	return chart_value(start, fin, weight)
