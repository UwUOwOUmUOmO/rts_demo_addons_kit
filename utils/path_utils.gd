extends Node

static func append_path(origin: String, derived: String) -> String:
	if origin[origin.length() - 1] in ['/', '\\']:
		return origin + derived
	else:
		return origin + '/' + derived

static func get_prequisites(dir_path: String, preq: PoolStringArray,\
		extension := ".res") -> Dictionary:
	var package := {}
	var dir := Directory.new()
	var err = dir.open(dir_path)
	OutputManager.error_check(err)
	if err != OK:
		return package
	for c in preq:
		package[c] = load(append_path(dir_path, c + extension))
	return package

static func create_dir(dir_path: String) -> int:
	var dir := Directory.new()
	var err := dir.open(dir_path)
	var count := 0
	if err == OK:
		return err
	err = dir.make_dir_recursive(dir_path)
	OutputManager.error_check(err, get_stack())
	return err

static func slice_path(origin: String) -> PoolStringArray:
	var pool := PoolStringArray()
	var temp := ""
	for c in origin:
		if c in ['/', '\\']:
			pool.push_back(temp)
			temp = ""
		else:
			temp += c
	if not temp.empty():
		pool.push_back(temp)
	return pool

static func join_path(sliced: PoolStringArray, sep := '/') -> String:
	var joined := ""
	for c in sliced:
		joined += c + sep
	return joined

static func res_save(path: String, res: Resource, flag := 0, extension := ".res")\
	-> int:
		var sliced_path := slice_path(path)
		sliced_path.resize(sliced_path.size() - 1)
		var dir_path := join_path(sliced_path)
		var err := create_dir(dir_path)
		if create_dir(dir_path) != OK:
			return err
		if not path.ends_with(extension):
			path += extension
		err = ResourceSaver.save(path, res, flag)
		OutputManager.error_check(err)
		return err

static func res_load(path: String):
	if not ResourceLoader.exists(path):
		OutputManager.print_error("Error: resource not exists: {path}"\
			.format({"path": path}), get_stack())
		return null
	else:
		return load(path)
