extends Serializable

class_name Bidding

var coprocess := false

# 0: Neutral
# 1: Running
# 2: Expired
var machine_state := 0
var function_state: GDScriptFunctionState = null
var yielded_to := ""

func __is_bidding():
	return true

func _init():
	
	# exclusion_list.append_array(["function_state", "yielded_to"])
	remove_properties(["function_state", "yielded_to"])
	name = "Bidding"
	return self


func _boot():
	pass

func _cycle(delta: float, target: Node):
	pass
