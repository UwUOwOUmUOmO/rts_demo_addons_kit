extends Serializable

class_name ReadonlyMask

# Persistent
var modifiable: PoolStringArray = []
var represented := {}

# Volatile
var host = null
var reveal_data := false
var data_mutex := Mutex.new()

func _init():
	name = "ReadonlyMask"
	remove_properties(["host", "serialization_mode", "reveal_data", "data_mutex"])

# func _get(property):
# 	match property:
# 		"modifiable": return modifiable
# 		"represented": return represented
# #		"name": return name
# #		"irid": return irid
# #		"property_list": return property_list
# #		"exclusion_list": return exclusion_list
# #		"no_deep_scan": return no_deep_scan
# 		_:
# 			if property in represented:
# 				return represented[property]
# 			return host.get(property)

# func _set(property, value):
# 	match property:
# 		"modifiable": modifiable = property
# 		"represented": represented = property
# #		"name": name = value
# #		"irid": irid = value
# #		"property_list": property_list = value
# #		"exclusion_list": exclusion_list = value
# #		"no_deep_scan": no_deep_scan = value
# 		_:
# 			# if property in modifiable:
# 			# 	Utilities.TrialTools.try_set(host, property, value)
# 			set_representation(property, value)
# #			represented[property] = value
# 	return true

# func edit(property: String, value):
# 	Utilities.TrialTools.try_set(host, property, value)

func get_exclusive(property: String, fallback):
	if reveal_data:
		return fallback
	if property in represented:
		return represented[property]
	return fallback

func set_exclusive(property: String, value) -> bool:
	if property in modifiable:
		return true
	# data_mutex.lock()
	represented[property] = value
	# data_mutex.unlock()
	return false

# func set_modifable(property: String, remove := false):
# 	if remove:
# 		modifiable.remove(modifiable.find(property))
# 	else:
# 		modifiable.push_back(property)

# func set_representation(property: String, value, remove := false):
# 	if remove:
# 		represented.erase(property)
# 	represented[property] = value
