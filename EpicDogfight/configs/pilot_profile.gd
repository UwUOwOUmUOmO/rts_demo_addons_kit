extends Configuration

class_name PilotProfile

# Persistant
var pilot_name := "Venom"

func _init(pname := ""):
    ._init()
    if not pname.empty():
        pilot_name = pname
