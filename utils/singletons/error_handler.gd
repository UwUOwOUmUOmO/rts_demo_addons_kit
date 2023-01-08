extends Node

onready var scene_tree := get_tree()
var allow_output := true
var allow_debug  := true
var trace_stack  := OS.is_debug_build()

func _init():
	randomize()

func timer(time: float) -> SceneTreeTimer:
	return get_tree().create_timer(time, false)

func push_stack(stack: Array):
	if not trace_stack:
		return
	var size := stack.size()
	for count in range(0, size):
		var curr: Dictionary = stack[count]
		var c: int = count
		print(("\t--- Stack trace ({layer}): function: {func}, " +\
		  "line: {line}, source: {source}").format({"layer": c, \
				"func": curr["function"], "line": curr["line"], \
				"source": curr["source"],}))

func error_check(ecode: int, stack := []):
	if ecode != OK:
		print_error("Error code: {code}".format({"code": ecode}), stack)

func print_fatal(err: String, stack := []):
	if allow_output:
		if not err.begins_with("[Fatal] "):
			err = "[Fatal] " + err
		printerr(err)
	push_stack(stack)
	var a = 7
	var b = 0
	var c = a / b 

func print_error(err: String, stack := []):
	if allow_output:
		if not err.begins_with("[Error] "):
			err = "[Error] " + err
		printerr(err)
	push_stack(stack)

func print_warning(warning: String, stack := []):
	if allow_output:
		if not warning.begins_with("[Warning] "):
			warning = "[Warning] " + warning
		print(warning)
	push_stack(stack)

func print_steamstat(message: String):
	if allow_output:
		if not message.begins_with("[Steam] "):
			message = "[Steam] " + message
		print(message)

func print_debug(msg: String, stack := []):
	if allow_debug and allow_output:
		if not msg.begins_with("[Debug] "):
			msg = "[Debug] " + msg
		print(msg)
	push_stack(stack)

func err_fail_condition(cond: bool, errstr: String, stack := []) -> bool:
	if allow_output and cond:
		Out.print_error(errstr, stack)
	return cond
