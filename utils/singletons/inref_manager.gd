extends Node

const READ_ONLY := true

var groups := {} setget set_groups, get_groups

var allow_probbing := false
var allow_query := true
var glock := Mutex.new()

func set_groups(_g):
	pass

func get_groups():
	if allow_probbing:
		if READ_ONLY:
			return groups.duplicate()
		return groups
	else:
		return {}

func clean(name: String) -> void:
	glock.lock()
	groups[name] = []
	glock.unlock()

func search_key(sample: String) -> Array:
	var found := []
	for key in groups:
		if sample in key:
			found.append(key)
	return found

func search_and_get(sample: String) -> Array:
	var found := []
	for key in groups:
		if sample in key:
			found.append_array(groups[key])
	return found

func query(input: FuncRef):
	if allow_query:
		if READ_ONLY:
			return input.call_func(groups.duplicate())
		return input.call_func(groups)
	return null

func fetch(name: String) -> Array:
	if not exists(name):
		return []
	return groups[name]

func exists(key: String) -> bool:
	return groups.has(key)

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
