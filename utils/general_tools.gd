extends Reference

class_name Toolkits

class PathTools extends Reference:

	static func append_path(origin: String, derived: String) -> String:
		return origin.plus_file(derived)

	static func get_prequisites(dir_path: String, preq: PoolStringArray,\
			extension := ".res") -> Dictionary:
		var package := {}
		var dir := Directory.new()
		var err = dir.open(dir_path)
		Out.error_check(err)
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
		Out.error_check(err, get_stack())
		return err

	static func slice_path(origin: String, identifiers := ['/', '\\']) -> PoolStringArray:
		var pool := PoolStringArray()
		var temp := ""
		for c in origin:
			if c in identifiers:
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
		joined.erase(joined.length() - 1, 1)
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
			Out.error_check(err)
			return err

	static func res_load(path: String):
		if not ResourceLoader.exists(path):
			Out.print_error("Resource not exists: {path}"\
				.format({"path": path}), get_stack())
			return null
		else:
			return load(path)

class SignalTools extends Reference:

	static func connect_from(from: Object, to: Object, table: Dictionary, \
			check := false, prompt := true) -> void:
		if not is_instance_valid(from) or not is_instance_valid(to):
			if prompt:
				Out.print_error("Invalid connection", get_stack())
			return
		for sig in table:
			var handler: String = table[sig]
			if check:
				if not to.has_method(handler):
					if prompt:
						Out.print_error("Signal receiver does not have method: " + handler, \
							get_stack())
					continue
			from.connect(sig, to, handler)

	static func disconnect_from(from: Object, to: Object, table := {}, \
			prompt := true) -> void:
		if table.empty():
			disconnect_all(from, to)
			return
		if not is_instance_valid(from) or not is_instance_valid(to):
			if prompt:
				Out.print_error("Invalid connection", get_stack())
			return
		for sig in table:
			var handler: String = table[sig]
			from.disconnect(sig, to, handler)

	static func disconnect_all(from: Object, to: Object):
		var all_signals := from.get_signal_list()
		for sig in all_signals:
			var sig_name: String = sig["name"]
			var connection_list := from.get_signal_connection_list(sig_name)
			for connection in connection_list:
				if connection["target"] == to:
					from.disconnect(sig_name, to, connection["method"])
