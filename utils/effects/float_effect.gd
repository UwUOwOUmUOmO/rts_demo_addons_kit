extends Effect

class_name FloatEffect

export var is_effecting := "" setget set_effecting
export(float, 0.0, 10.0) var percent_up   := 0.0
export(float, 0.0, 10.0) var percent_down := 0.0
export(float, -100.0, 100.0, 0.1) var exponent := 1.0
export var clamp_up   := 0.0 setget set_clamp_up
export var clamp_down := 0.0 setget set_clamp_down

func _init():
	name = "FloatEffect"
	effect_name = name

func set_effecting(e: String):
	is_effecting = e
	category_name = e

func set_clamp_up(c: float):
	clamp_up = c
	clamp_check()

func set_clamp_down(c: float):
	clamp_down = c
	clamp_check()

func clamp_check():
	clamp_down = min(clamp_down, clamp_up)

func take_effect(original_value: float, modified_value: float) -> float:
	var new_value := modified_value
	new_value += percent_up   * original_value
	new_value -= percent_down * original_value
	new_value += pow(original_value, exponent)
	if clamp_down != clamp_up:
		new_value = clamp(new_value, clamp_down, clamp_up)
	return new_value
