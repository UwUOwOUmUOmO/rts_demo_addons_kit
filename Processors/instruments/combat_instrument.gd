extends Processor

class_name CombatInstrument

# Volatile
var green_light := false

func _init():
	exclusion_list.append_array(["green_light"])
	._init()
	name = "CombatInstrument"
	return self

func _controller_instrument_changed(new_instrument, controller):
	if new_instrument != self:
		green_light = false
		controller.disconnect("__computer_changed", self,\
			"_controller_computer_changed")

func _reset_volatile() -> void:
	._reset_volatile()
	green_light = false
