extends Control

onready var output: Label = $out

export(int) var output_limit := -1
var table := {}

func make_text() -> String:
	var re := ""
	var size = table.size()
	if size == 0:
		return re
	var lesser_limit := 0
	if output_limit != -1:
		lesser_limit = size - output_limit
	for iter in range(lesser_limit, size):
		var key = table.keys()[iter]
		var value = table[key]
		var line = "{iname}: {val}\n"\
			.format({"iname": key, "val": value})
		re += line
	return re

func update_output():
	output.text = make_text()

func _process(_delta):
	update_output()
