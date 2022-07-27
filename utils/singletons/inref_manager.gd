extends Node

const READ_ONLY := true

var local_irm: Node = null
var glock := Mutex.new()

func get_groups():
	return local_irm.groups

func clean(name: String) -> void:
	glock.lock()
	local_irm.groups[name] = []
	glock.unlock()

func search_key(sample: String) -> Array:
	var found := []
	for key in local_irm.groups:
		if sample in key:
			found.append(key)
	return found

func search_and_get(sample: String) -> Array:
	var found := []
	for key in local_irm.groups:
		if sample in key:
			found.append_array(local_irm.groups[key])
	return found

func query(input: FuncRef):
	if local_irm.allow_query:
		if READ_ONLY:
			return input.call_func(local_irm.groups.duplicate())
		return input.call_func(local_irm.groups)
	return null

func fetch(name: String) -> Array:
	if not exists(name):
		return []
	return local_irm.groups[name]

func exists(key: String) -> bool:
	return local_irm.groups.has(key)

func add(ref: InRef, to: PoolStringArray) -> void:
	if to.empty():
		return
	glock.lock()
	for part in to:
		if part in ref.participation:
			continue
		if not local_irm.groups.has(part):
			local_irm.groups[part] = []
		local_irm.groups[part].append(ref)
		ref.participation.append(part)
	glock.unlock()

func remove(ref: InRef, from: PoolStringArray) -> bool:
	if from.empty():
		return false
	glock.lock()
	for part in from:
		if not part in ref.participation or not local_irm.groups.has(part):
			glock.unlock()
			return false
		local_irm.groups[part].erase(ref)
		ref.participation.erase(part)
	glock.unlock()
	return true

func cut_tie(ref: InRef):
	glock.lock()
	var plist := ref.participation
	for group in plist:
		local_irm.groups[group].erase(ref)
	glock.unlock()
