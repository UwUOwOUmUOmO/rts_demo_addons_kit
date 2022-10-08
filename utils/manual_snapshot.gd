extends Reference

class_name MaunalSnapShot

var slots := [null, null, null]
var host: Serializable = null setget set_host

var limit := 3 setget resize
var slot_count := 0
var slots_mutex := Mutex.new()

func set_host(h: Serializable):
	host = h

func resize(new_size: int):
	if new_size < 1:
		return
	limit = new_size
	if limit < slot_count:
		slots.resize(limit)

func snap():
	var new_snapshot := {}
	for item in host.property_list:
		var value = host.get(item)
		new_snapshot[item] = value
	slots_mutex.lock()
	if slot_count == limit:
		slots.resize(limit - 1)
		slots.push_front(new_snapshot)
	slots_mutex.unlock()

func restore(index := 0):
	var snapshot := get_slot(index)
	slots_mutex.lock()
	for item in host.property_list:
		var new_value = snapshot[item]
		host.set(item, new_value)
	slots_mutex.unlock()

func get_slot(index: int) -> Dictionary:
	return slots[clamp(index, 0, limit - 1)]
