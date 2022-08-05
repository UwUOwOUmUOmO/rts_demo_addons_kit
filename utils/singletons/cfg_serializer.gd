extends Node

const CFG_VER := PoolIntArray([1, 3, 0])
const ALLOWED_INHERITANCE: PoolStringArray = PoolStringArray([
	"Configuration",
])

var allowed_serializable := {} setget set_forbidden, get_forbidden

func set_forbidden(f):
	pass

func get_forbidden():
	return null

func set_serializable():
	var all_classes: Array = ProjectSettings.get_setting("_global_script_classes")
	for c in all_classes:
		if c["base"] in ALLOWED_INHERITANCE or c["class"] in ALLOWED_INHERITANCE:
			allowed_serializable[c["class"]] = c["path"]

class Serializer_AssistClass extends Reference:
	var original_cfg: Configuration = null
	var final := {}
	var allowed_serializable := {}
	var id := 0

	func _init(cfg: Configuration, allowed: Dictionary):
		original_cfg = cfg
		allowed_serializable = allowed

	func get_id() -> int:
		id += 1
		return id - 1

	func serialize():
		final = {
			"__cfg_ver": CFG_VER,
			"__entry": id,
		}
		serializer_worker(original_cfg)

	func prompt_not_allowed(c_name: String):
		Out.print_error("Serialization of class {cname} is not allowed"\
			.format({"cname": c_name}), get_stack())

	func s_dict(dict: Dictionary) -> Dictionary:
		var re := {}
		var has_branch := false
		re["__has_branch"] = has_branch
		for key in dict:
			var value = dict[key]
			var serialized = value
			var check := true
			if value is Resource:
				serialized = s_res(value)
			elif value is Dictionary:
				serialized = s_dict(value)
			elif value is Array:
				serialized = s_arr(value)
			else:
				check = false
			if check:
				has_branch = true
			re[key] = serialized
		re["__has_branch"] = has_branch
		return re
	
	func s_arr(arr: Array) -> Array:
		var re := []
		var has_branch := false
		re.append(has_branch)
		for val in arr:
			var serialized = val
			var check := true
			if val is Resource:
				serialized = s_res(val)
			elif val is Dictionary:
				serialized = s_dict(val)
			elif val is Array:
				serialized = s_arr(val)
			else:
				check = false
			if check:
				has_branch = true
			re.append(serialized)
		re[0] = has_branch
		return re

	func s_res(res: Resource) -> Dictionary:
		# Check if this resource has any script
		# if yes, check if it's allowed to serialize
		var failed := false
		var re := {}
		if res.get_script() != null:
			if not "name" in res:
				failed = true
			elif not res.name in allowed_serializable:
				failed = true
			if failed:
				prompt_not_allowed(res.name)
				return re
			return serializer_worker(res)
		# Serialize Resource for real
		var loc := res.resource_path
		if not loc.empty():
			var err := ResourceSaver.save(loc, res)
			Out.error_check(err, get_stack())
			re["__res_loc"] = loc
			re["__res_class"] = res.get_class()
		return re

	func serializer_worker(curr_cfg: Configuration) -> Dictionary:
		var re := {}
		var id := get_id()
		var pointer := {"__entry": id}
		final[id] = re
		if not curr_cfg.name in allowed_serializable:
			prompt_not_allowed(curr_cfg.name)
			return pointer
		re["__cfg_base_class"] = curr_cfg.get_class()
		re["__cfg_class_name"] = curr_cfg.name
		for var_name in curr_cfg.property_list:
			var variable = curr_cfg.get(var_name)
			var serialized = null
			if variable is Node:
				continue
			elif variable is Resource:
				serialized = s_res(variable)
			else:
				# Non-Object variables
				if variable is Array:
					if not var_name in curr_cfg.no_deep_scan:
						serialized = s_arr(variable)
				elif variable is Dictionary:
					if not var_name in curr_cfg.no_deep_scan:
						serialized = s_dict(variable)
				else:
					serialized = variable
			re[var_name] = serialized
		return pointer

class Deserializer_AssistClass extends Reference:
	var allowed_serializable := {}
	var serialized := {}
	var final = null
	var full_completion := true

	func prompt_not_allowed(c_name: String):
		Out.print_error("Deserialization of class {cname} is not allowed"\
			.format({"cname": c_name}), get_stack())

	func prompt_no_base_class(bc_name: String):
		Out.print_error("Failed to instance base class: " + bc_name, get_stack())

	func prompt_no_entry(e_name: String):
		Out.print_error("Failed to import property: " + e_name, get_stack())

	func prompt_no_outsider(loc: String):
		Out.print_error("Resource path must be inside 'res://': " + loc, get_stack())

	func _init(ser: Dictionary, allowed: Dictionary):
		serialized = ser
		allowed_serializable = allowed

	func version_check(ver: PoolIntArray) -> bool:
		var max_sub_ver := 3
		var curr_verr := CFG_VER
		for iter in range(0, max_sub_ver):
			if ver[iter] > curr_verr[iter]:
				Out.print_error("Current CFG_VER is lower than given Configuration's", get_stack())
				return false
		return true

	func deserialize():
		if not version_check(serialized["__cfg_ver"]):
			return
		var entry = serialized["__entry"]
		var main_part: Dictionary = serialized[entry]
		final = deserializer_worker(main_part)

	func deserialize_to(target):
		if not version_check(serialized["__cfg_ver"]):
			return
		var entry = serialized["__entry"]
		var main_part: Dictionary = serialized[entry]
		final = deserializer_worker(main_part, target)

	func d_dict(dict: Dictionary):
		# Convention Dictionary
		if dict.has("__has_branch"):
			var has_branch: bool = dict["__has_branch"]
			dict.erase("__has_branch")
			if not has_branch:
				return dict
			else:
				var re := {}
				for key in dict:
					if key.begins_with("__"):
						continue
					var value = dict[key]
					if value is Dictionary:
						re[key] = d_dict(value)
					elif value is Array:
						re[key] = d_arr(value)
					else:
						re[key] = value
				return re
		# Serialized object
		if dict.has("__entry"):
			var branch: Dictionary = serialized[dict["__entry"]]
			return deserializer_worker(branch)
		elif dict.has("__res_loc"):
			return d_res(dict)
		return null

	func d_arr(arr: Array):
		# Check for branches
		if not arr.pop_back():
			return arr
		var re := []
		for c in arr:
			if c is Dictionary:
				re.append(d_dict(c))
			elif c is Array:
				re.append(d_arr(c))
			else:
				re.append(c)
		return re

	func d_res(res: Dictionary):
		var res_loc: String = res["__res_loc"]
		if not res_loc.begins_with("res://"):
			prompt_no_outsider(res_loc)
			return null
		return ResourceLoader.load(res_loc, res["__res_class"])

	func deserializer_worker(ser: Dictionary, deserialized = null):
		# Exploitation check
		var full_completion := true
		var target_name: String = ser["__cfg_class_name"]
		if not target_name in allowed_serializable:
			prompt_not_allowed(target_name)
			return deserialized
		var bc_name: String = ser["__cfg_base_class"]
		if deserialized == null:
			deserialized = ClassDB.instance(bc_name)
			if not is_instance_valid(deserialized):
				prompt_no_base_class(bc_name)
				return
			var target_path: String = allowed_serializable[target_name]
			var target_script: Script = ResourceLoader.load(target_path, "Script")
			deserialized.set_script(target_script)
		# Start deserialization
		for var_name in deserialized.property_list:
			var final_instance = null
			if not ser.has(var_name):
				prompt_no_entry(var_name)
				full_completion = false
				continue
			final_instance = ser[var_name]
			if not var_name in deserialized.no_deep_scan:
				if final_instance is Dictionary:
					final_instance = d_dict(final_instance)
				elif final_instance is Array:
					final_instance = d_arr(final_instance)
			deserialized.set(var_name, final_instance)
		full_completion = full_completion and deserialized._data_correction()
		return deserialized

func _ready():
	set_serializable()
#	for k in allowed_serializable:
#		print("{class}: {path}".format({"class": k, "path": allowed_serializable[k]}))

func serialize(cfg: Configuration) -> Dictionary:
	var assist := Serializer_AssistClass.new(cfg, allowed_serializable)
	assist.serialize()
	return assist.final

func deserialize(ser: Dictionary):
	var assist := Deserializer_AssistClass.new(ser, allowed_serializable)
	assist.deserialize()
	return assist.final

func deserialize_to(ser: Dictionary, target):
	var assist := Deserializer_AssistClass.new(ser, allowed_serializable)
	assist.deserialize_to(target)
