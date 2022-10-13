extends Reference

class_name Utilities

class BitMask extends Reference:

	const BIT_0					:= 0
	const BIT_1					:= 1
	const BIT_2					:= 2
	const BIT_3					:= 4
	const BIT_4					:= 8
	const BIT_5					:= 16
	const BIT_6					:= 32
	const BIT_7					:= 64
	const BIT_8					:= 128
	const BIT_9					:= 256
	const BIT_10				:= 512
	const BIT_11				:= 1024
	const BIT_12				:= 2048
	const BIT_13				:= 4096
	const BIT_14				:= 8192
	const BIT_15				:= 16384
	const BIT_16				:= 32768
	const BIT_17				:= 65536
	const BIT_18				:= 131072
	const BIT_19				:= 262144
	const BIT_20				:= 524288
	const BIT_21				:= 1048576
	const BIT_22				:= 2097152
	const BIT_23				:= 4194304
	const BIT_24				:= 8388608
	const BIT_25				:= 16777216
	const BIT_26				:= 33554432
	const BIT_27				:= 67108864
	const BIT_28				:= 134217728
	const BIT_29				:= 268435456
	const BIT_30				:= 536870912
	const BIT_31				:= 1073741824
	const BIT_32				:= 2147483648

	const BITMASK_1ST_WORD		:= 15
	const BITMASK_2ND_WORD		:= 240
	const BITMASK_3RD_WORD		:= 3480
	const BITMASK_4TH_WORD		:= 61440
	const BITMASK_5TH_WORD		:= 983040
	const BITMASK_6TH_WORD		:= 15728640
	const BITMASK_7TH_WORD		:= 251658240
	const BITMASK_8TH_WORD		:= 4026531840
	const BITMASK_32BITS_ALL	:= 4294967295
	const BITMASK_48BITS_ALL	:= 281474976710655

	const MAX_PROCESSABLE_BITMASK_SINGLE := 48
	const MAX_PROCESSABLE_BITMASK_WORD := 8

	static func bitmask_join_single(block: PoolIntArray) -> int:
		var mask := 0
		if block.size() > MAX_PROCESSABLE_BITMASK_SINGLE:
			block.resize(MAX_PROCESSABLE_BITMASK_SINGLE)
		for iter in range(0, block.size()):
			if block[iter]:
				mask += pow(2, iter + 1)
		return mask

	static func bitmask_join_word(block: PoolIntArray) -> int:
		var mask := 0
		if block.size() > MAX_PROCESSABLE_BITMASK_WORD:
			block.resize(MAX_PROCESSABLE_BITMASK_WORD)
		for iter in range(0, block.size()):
			if block[iter]:
				match iter:
					0:
						mask += BITMASK_1ST_WORD
					1:
						mask += BITMASK_2ND_WORD
					2:
						mask += BITMASK_3RD_WORD
					3:
						mask += BITMASK_4TH_WORD
					4:
						mask += BITMASK_5TH_WORD
					5:
						mask += BITMASK_6TH_WORD
					6:
						mask += BITMASK_7TH_WORD
					7:
						mask += BITMASK_8TH_WORD
			# ------------------------
			iter += 1
		return mask

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
				Out.print_error("Invalid connection from {f} to {t}" \
					.format({"f": str(from), "t": str(to)}), get_stack())
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
				Out.print_error("Invalid connection from {f} to {t}" \
					.format({"f": str(from), "t": str(to)}), get_stack())
			return
		for sig in table:
			var handler: String = table[sig]
			from.disconnect(sig, to, handler)

	static func disconnect_all(from: Object, to: Object = null):
		var all_signals := from.get_signal_list()
		for sig in all_signals:
			var sig_name: String = sig["name"]
			var connection_list := from.get_signal_connection_list(sig_name)
			for connection in connection_list:
				if to == null or connection["target"] == to:
					from.disconnect(sig_name, connection["target"], connection["method"])

class TrialTools extends Reference:
	
	const allow_output := false

	static func default_fallback_evaluation(target, property_name: String, is_function := false):
		if not target is Object or not is_instance_valid(target):
			return false
		if  (not property_name in target and not is_function)  or \
			(not target.has_method(property_name) and is_function):
				return false
		return true

	static func try_set(target: Object, prop: String, value, deferred := false):
		var path: Array = PathTools.slice_path(prop, ['.'])
		var final_prop = path.pop_back()
		var final_path := PathTools.join_path(path, '.')
		var final_instance = try_get(target, final_path)
		if default_fallback_evaluation(final_instance, final_prop):
			if not deferred:
				final_instance.set(final_prop, value)
			else:
				final_instance.set_deferred(final_prop, value)
		elif allow_output:
			Out.print_error("Failed to set value {path} on base {obj}"\
				.format({"path": prop, "obj": str(target)}), get_stack())

	static func try_get(target: Object, prop: String, default = null):
		if prop.empty():
			return target
		var instance = target
		var path: Array = PathTools.slice_path(prop, ['.'])
		var curr_prop = path.pop_front()
		var completed := true
		while curr_prop != null:
			if not instance is Object:
				completed = false
				break
			if curr_prop in instance:
				instance = instance.get(curr_prop)
			else:
				completed = false
				break
			curr_prop = path.pop_front()
		if completed:
			return instance
		else:
			return default

	static func try_append(target: Object, prop: String, value):
		var instance = try_get(target, prop)
		if instance is Array:
			instance.append(value)
		elif allow_output:
			Out.print_error("Failed to append to [{obj}].{path}"\
				.format({"obj": target, "path": prop}), get_stack())

	static func try_arr_index(target, index):
		if not target is Array or not index is int:
			return null
		if target.size() - 1 < index:
			return null
		return target[index]

	static func try_dict_index(target, index):
		if not target is Dictionary:
			return null
		if not index in target:
			return null
		return target[index]

	static func try_index(target: Object, prop: String, index):
		var instance = try_get(target, prop)
		var re = try_arr_index(instance, index)
		if re != null:
			return re
		return try_dict_index(instance, index)

	static func try_call(target: Object, fname: String, args := [], default = null):
		var path: Array = PathTools.slice_path(fname, ['.'])
		var final_fname: String = path.pop_back()
		var final_path := PathTools.join_path(path, '.')
		var final_instance = try_get(target, final_path)
		if default_fallback_evaluation(final_instance, final_fname, true):
			var fref := funcref(final_instance, final_fname)
			return fref.call_funcv(args)
		return default

	static func try_singleton_call(target: String, property: String, args := []):
		var service = SingletonManager.fetch(target)
		return try_call(service, property, args)
	
	static func try_divide(divisor: float, dividend: float) -> float:
		if dividend != 0.0:
			return divisor / dividend
		return 0.0

	static func try_propagate(from, method: String, args := []) -> void:
		if from is Array:
			for component in from:
				if component is Array or component is Dictionary:
					try_propagate(component, method, args)
				elif component is Object:
					try_call(component, method, args)
		elif from is Dictionary:
			for key in from:
				var component = from[key]
				if component is Array or component is Dictionary:
					try_propagate(component, method, args)
				elif component is Object:
					try_call(component, method, args)
		return

class ProfilingTools extends Reference:

	static func benchmark(function: FuncRef, args := [], auto_output := false) -> int:
		var start := Time.get_ticks_usec()
		var re = function.call_funcv(args)
		var end := Time.get_ticks_usec()
		var perf := end - start
		if not auto_output:
			return perf
		Out.print_debug("Benchmark result for {fname}: {result} microsecond(s)"\
			.format({"fname": function.function, "result": perf}))
		return perf
