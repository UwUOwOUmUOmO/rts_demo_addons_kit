extends Node

var groups := {}
var gc := false

var glock := Mutex.new()

func clean(name: String) -> void:
	glock.lock()
	groups[name] = []
	glock.unlock()

func fetch(name: String) -> Array:
	if not groups.has(name):
		return []
	return groups[name]

func add(ref: InRef, to: PoolStringArray) -> void:
	if to.empty():
		return
	glock.lock()
	for part in to:
		if part in ref.participation:
			continue
		if not groups.has(part):
			groups[part] = []
		groups[part].append(ref)
		ref.participation.append(part)
		pass
	glock.unlock()

func remove(ref: InRef, from: PoolStringArray) -> bool:
	if from.empty():
		return false
	glock.lock()
	for part in from:
		if not part in ref.participation or not groups.has(part):
			glock.unlock()
			return false
		groups[part].erase(ref)
		ref.participation.erase(part)
	glock.unlock()
	return true

func cut_tie(ref: InRef):
	glock.lock()
	var plist := ref.participation
	for group in plist:
		groups[group].erase(ref)
	glock.unlock()
