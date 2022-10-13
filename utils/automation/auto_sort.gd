extends Serializable

class_name AutoSort

# Persistent
var indexes: PoolRealArray = []
var values := []

# Volatile
var vmutex := Mutex.new()

func _init():
	name = "AutoSort"
	remove_property("vmutex")

func push(index: float, value):
	vmutex.lock()
	if indexes.size() == 0:
		indexes.push_back(index)
		values.append(value)
	else:
		var id := 0
		while true:
			if id == indexes.size() - 1:
				indexes.push_back(index)
				values.append(value)
				break
			elif index < indexes[id + 1]:
				indexes.insert(id, index)
				values.insert(id, value)
				break
			id += 1
			if id >= indexes.size():
				break
	vmutex.unlock()

func pull(index: float):
	var loc := indexes.find(index)
	if loc < 0: return null
	return values[loc]
