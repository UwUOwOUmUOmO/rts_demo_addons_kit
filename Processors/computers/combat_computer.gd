extends Processor

class_name CombatComputer

# Volatile
var memory := {}
var target: Combatant = null
var vessel: Combatant = null
var all_check := false

# Persistance
var coprocess := true

func _controller_computer_changed(new_computer, controller):
	if new_computer != self:
		all_check = false
		controller.disconnect("__computer_changed", self,\
			"_controller_computer_changed")

func _vessel_change_handler(new_vessel):
	vessel = new_vessel

func _target_change_handler(new_target):
	target = new_target

func _target_defeated_handler():
	target = null

func _import(config: Dictionary) -> void:
	._import(config)
	coprocess = bool(config["coprocess"])

func _export() -> Dictionary:
	var original := ._export()
	var re := {
		"coprocess": int(coprocess)
	}
	return dictionary_append(original, re)

func _reset_volatile():
	._reset_volatile()
	memory = {}
	target  = null
	vessel  = null
	all_check = false
