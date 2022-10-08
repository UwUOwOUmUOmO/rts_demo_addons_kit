extends Serializable

class_name CombatantConfiguration

# Persistent
var hullProfile := HullProfile.new()
# var rom	:= ReadonlyMask.new()

# Volatile
# var data_mutex := Mutex.new()
# var thread_safe_access := false

func _init():
	name = "CombatantConfiguration"
# 	rom.host = self

# func _serialize_notifier(in_progress: bool):
# 	rom.reveal_data = in_progress

# func _get(property):
# 	match property:
# 		"rom":
# 			return rom
# 		_:
# 			var actual = get(property)
# 			return rom.get_exclusive(property, actual)

# func _set(property, value):
# 	# if thread_safe_access: data_mutex.lock()
# 	match property:
# 		"rom":
# 			rom = value
# 		_:
# 			if rom.set_exclusive(property, value):
# 				set(property, value)
# 	# if thread_safe_access: data_mutex.unlock()
# 	return true

# func get_uncensored(property: String):
# 	return get(property)

# func set_uncensored(property: String, value):
# 	return set(property, value)

# func set_tsa(v: bool):
# 	data_mutex.lock()
# 	thread_safe_access = v
# 	data_mutex.unlock()
