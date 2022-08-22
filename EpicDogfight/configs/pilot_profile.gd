extends Serializable

class_name PilotProfile

# Persistant
var pilot_name := "Venom"

func _init(pname := ""):
	name = "PilotProfile"
	if not pname.empty():
		pilot_name = pname
