extends Control

onready var output: Label = $out

export(bool) var pause_update := false
export(bool) var use_physics_process := false
export(int) var output_limit := -1
export(int, 1, 200) var separator_character_count := 1 setget set_scc
export(String, "Dash", "Asterisk") var separator_character := "Dash" setget set_sc
export(PoolStringArray) var separators := PoolStringArray()
var table := {}

var sep_premade := "*"
var sep_char := "-"

func set_scc(count: int):
	separator_character_count = count
	sep_premade = make_separator()

func set_sc(st: String):
	separator_character = st
	if st == "Dash":
		sep_char = "-"
	elif st == "Asterisk":
		sep_char = "*"
	set_scc(separator_character_count)

func make_separator() -> String:
	var re := ""
	for c in range(0, separator_character_count):
		re += sep_char
	re += "\n"
	return re

func make_text() -> String:
	var re := ""
	var size = table.size()
	if size == 0:
		return re
	var lesser_limit := 0
	var sep_dup := Array(separators)
	var sep_key = sep_dup.pop_front()
	if output_limit != -1:
		lesser_limit = size - output_limit
	for iter in range(lesser_limit, size):
		var key = table.keys()[iter]
		var value = table[key]
		var line = "{iname}: {val}\n"\
			.format({"iname": key, "val": value})
		re += line
		if key == sep_key:
			re += sep_premade
			sep_key = sep_dup.pop_front()
	return re

func update_output():
	output.text = make_text()

func _process(_delta):
	if not use_physics_process and not pause_update:
		update_output()

func _physics_process(_delta):
	if use_physics_process and not pause_update:
		update_output()
