extends Reference

class_name MaunalSnapShot

var host: Serializable = null setget set_host
var slots := [null, null, null]
var changes: PoolStringArray = []

var changes_comparision := true
var limit := 3 setget resize
var slots_mutex := Mutex.new()

func set_host(h: Serializable):
	host = h
	slots = []
	changes = []

func resize(new_size: int):
	if new_size < 1:
		return
	limit = new_size
	slots_mutex.lock()
	slots.resize(limit)
	slots_mutex.unlock()

func snap() -> Dictionary:
	var old_snapshot := {}
	if not slots.empty():
		old_snapshot = slots[0]
	var new_snapshot := {}
	var new_changes: PoolStringArray = []
	for item in host.property_list:
		var value = host.get(item)
		if not old_snapshot.empty() and changes_comparision:
			var old_value = old_snapshot[item]
			if value is Object:
				if value.get_instance_id() != old_value.get_instance_id():
					new_changes.push_back(item)
			elif value is Dictionary or value is Array:
				if value.hash() != old_value.hash():
					new_changes.push_back(item)
			elif value != old_value:
				new_changes.push_back(item)
		new_snapshot[item] = value
	slots_mutex.lock()
	changes = new_changes
	if slots.size() == limit - 1:
		slots.resize(limit - 1)
		slots.push_front(new_snapshot)
	slots_mutex.unlock()
	return new_snapshot

func restore(index := 0):
	var snapshot := get_slot(index)
	slots_mutex.lock()
	for item in host.property_list:
		var new_value = snapshot[item]
		host.set(item, new_value)
	slots_mutex.unlock()

func get_slot(index: int) -> Dictionary:
	return slots[clamp(index, 0, limit - 1)]
