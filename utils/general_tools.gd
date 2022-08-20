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

class TrialTools extends Reference:

	static func default_fallback_evaluation(target, property_name: String, is_function := false):
		if not target is Object or not is_instance_valid(target):
			return false
		if  (not property_name in target and not is_function)  or \
			(not target.has_method(property_name) and is_function):
				return false
		return true

	static func try_set(target: Object, prop: String, value):
		var path: Array = PathTools.slice_path(prop, ['.'])
		var final_prop = path.pop_back()
		var final_path := PathTools.join_path(path, '.')
		var final_instance = try_get(target, final_path)
		if default_fallback_evaluation(final_instance, final_prop):
			final_instance.set(final_prop, value)

	static func try_get(target: Object, prop: String, next_to_final := false):
		var instance := target
		var path: Array = PathTools.slice_path(prop, ['.'])
		if next_to_final:
			path.pop_back()
		var curr_prop = path.pop_front()
		while curr_prop != null and instance is Object:
			if curr_prop in instance:
				instance = instance.get(curr_prop)
			else:
				instance = null
			curr_prop = path.pop_front()
		return instance

	static func try_append(target: Object, prop: String, value):
		var instance = try_get(target, prop)
		if instance is Array:
			instance.append(value)

	static func try_call(target: Object, fname: String, args := []):
		var path: Array = PathTools.slice_path(fname, ['.'])
		var final_fname: String = path.pop_back()
		var final_path := PathTools.join_path(path, '.')
		var final_instance = try_get(target, final_path)
		if default_fallback_evaluation(final_instance, final_fname, true):
			var fref := funcref(final_instance, final_fname)
			return fref.call_funcv(args)
		return null

	static func try_singleton_call(target: String, property: String, args := []):
		var service = SingletonManager.fetch(target)
		return try_call(service, property, args)
