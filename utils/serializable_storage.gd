extends Serializable

class_name SerializableStorage

# Volatile
var memory := {}

# Persistent
var storage := {}

func _init():
	
	remove_property("memory")
	
	name = "SerializableStorage"

func get_storage(dup := true):
	if dup:
		return storage.duplicate(true)
	return storage

func fetch(key: String):
	return storage[key]

func set_deep_scan(yes := false):
	if yes:
		var arr := Array(no_deep_scan)
		arr.erase("storage")
		no_deep_scan = arr
	else:
		no_deep_scan.push_back("storage")

func merge(from := memory):
	storage = dict_append(from, storage, false, false)

static func dict_append(from: Dictionary, to: Dictionary, replace := true, dup := true) \
		-> Dictionary:
	var re: Dictionary
	if dup:
		re = to.duplicate(true)
	else:
		re = to
	for key in from:
		if (key in re) and not replace:
			continue
		re[key] = from[key]
	return re
