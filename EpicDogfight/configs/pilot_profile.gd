extends Configuration

class_name PilotProfile

# Persistant
var pilot_name := "Venom"

func _init(pname := ""):
	
	if not pname.empty():
		pilot_name = pname
