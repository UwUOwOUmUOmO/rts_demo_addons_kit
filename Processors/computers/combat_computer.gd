extends Processor

class_name CombatComputer

# Volatile
var memory := {}
var target: Combatant = null
var vessel: Combatant = null
var controller = null
var all_check := false

# Persistance
var coprocess := true

func _init():
	
	# exclusion_list.append_array(["memory", "target", "vessel", "all_check"])
	remove_properties(["memory", "target", "vessel", "all_check"])
	name = "CombatComputer"
	return self

func _reset_volatile():
	._reset_volatile()
	memory = {}
	target = null
	vessel = null
	all_check = false

func _controller_computer_changed(_con, new_computer):
	if new_computer != self:
		# Stop process
		all_check = false
		# Terminate Processor
		terminated = true
		# _con.disconnect("__computer_changed", self,\
		# 	"_controller_computer_changed")

func _vessel_change_handler(new_vessel):
	vessel = new_vessel

func _target_change_handler(new_target):
	target = new_target

func _target_defeated_handler(_con):
	target = null
