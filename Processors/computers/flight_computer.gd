extends CombatComputer

class_name FlightComputer

enum COMPUTER_TYPE {AAF, AAM, AGM}

var type = COMPUTER_TYPE.AAF
var coprocess := true

static func type_parsing(t, reversed := false):
	if not reversed:
		if t == "AAM":
			return COMPUTER_TYPE.AAM
		elif t == "AGM":
			return COMPUTER_TYPE.AGM
		else:
			return COMPUTER_TYPE.AAF
	else:
		if t == COMPUTER_TYPE.AAM:
			return "AAM"
		elif t == COMPUTER_TYPE.AGM:
			return "AGM"
		else:
			return "AAF"

func _import(config: Dictionary):
	type = type_parsing(config["type"])
	coprocess = bool(config["coprocess"])

static func _export(computer: FlightComputer):
	var data := {
		"type": type_parsing(computer.type, true),
		"coprocess": int(computer.coprocess),
	}
	return data
