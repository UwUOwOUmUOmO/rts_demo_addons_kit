extends CombatComputer

class_name FlightComputer

enum DEVICE_TYPE {AAF, AAM, AGM}

const DEFAULT_DEVICE = DEVICE_TYPE.AAF
const DEFAULT_DEVICE_STR = "AAF"

# Persistent
var type = DEFAULT_DEVICE

static func type_parsing(t, reversed := false):
	if not reversed:
		if t == "AAM":
			return DEVICE_TYPE.AAM
		elif t == "AGM":
			return DEVICE_TYPE.AGM
		else:
			return DEFAULT_DEVICE
	else:
		if t == DEVICE_TYPE.AAM:
			return "AAM"
		elif t == DEVICE_TYPE.AGM:
			return "AGM"
		else:
			return DEFAULT_DEVICE_STR

func _import(config: Dictionary):
	._import(config)
	type = type_parsing(config["type"])

func _export() -> Dictionary:
	var original := ._export()
	var re := {
		"type": type_parsing(type, true),
	}
	return dictionary_append(original, re)
