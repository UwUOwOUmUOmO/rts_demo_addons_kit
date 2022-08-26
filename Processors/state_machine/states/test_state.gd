extends StateSingular

class_name TestState

var interval := 1.0
var timer := 0.0
var is_yield_test := false
var yielded := false

func _compute(delta: float):
	if is_yield_test:
		if yielded:
			return null
		Out.print_debug("I'm yielding")
		yield()
		Out.print_debug("I yielded")
		yielded = true
		return
	timer += delta
	if timer > interval:
		Out.print_debug("It's been {t} second(s)".format({"t": timer}))
		timer = 0.0
	return null

func _finalize():
	._finalize()
	Out.print_debug("I'm free!!!!!")
