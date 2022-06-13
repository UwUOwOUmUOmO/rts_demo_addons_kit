extends Node

var allow_output := true
var trace_stack  := true

func push_stack(stack: Array):
	if not trace_stack:
		return
	var size := stack.size()
	for count in range(0, size):
		var curr: Dictionary = stack[count]
		var c: int = count
		print("Stack trace: function: {func}, line: {line}," +\
		  "source: {source}".format({"layer": c, "func": curr["function"],\
				"line": curr["line"], "source": curr["source"]}))

func error_check(ecode: int, stack := []):
	if ecode != OK:
		print_error("Error code: {code}".format({"code": ecode}), stack)

func print_error(err: String, stack := []):
	if allow_output:
		printerr(err)
	push_stack(stack)

func print_warning(warning: String, stack := []):
	if allow_output:
		print(warning)
	push_stack(stack)
