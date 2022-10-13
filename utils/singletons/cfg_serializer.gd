extends Node

class_name SerializationServer

const ALLOWED_INHERITANCE: PoolStringArray = PoolStringArray([
	"Serializable",
])

var allowed_serializable := {} setget set_forbidden, get_allowed

func set_forbidden(f):
	pass

func get_allowed():
	if OS.is_debug_build():
		return allowed_serializable.duplicate()
	return null

func explore_tree(parental_tree: Dictionary, find_what: String) -> Array:
	var found := []
	var iter := 0
	var size := parental_tree.size()
	var keys := parental_tree.keys()
	var values := parental_tree.values()
	while iter < size:
		var result := values.find(find_what, iter)
		if result == -1:
			break
		iter = result + 1
		found.append(keys[result])
	if not found.empty():
		for res in found:
			parental_tree.erase(res)
#		for res in found:
			found.append_array(explore_tree(parental_tree, res))
	return found

func find_dup(arr: Array) -> Array:
	var dup_list := []
	for iter in range(arr.size()):
		var value = arr[iter]
		if iter == arr.size() - 1:
			break
		var find_result := arr.find(value, iter + 1)
		if find_result > -1:
			dup_list.append(value)
	return dup_list

func set_serializable_worker():
	var all_classes: Array = ProjectSettings.get_setting("_global_script_classes")
	var address_record := {}
	var parental_record := {}
	for c in all_classes:
		address_record[c["class"]] = c["path"]
		parental_record[c["class"]] = c["base"]
	var allowed := Array(ALLOWED_INHERITANCE)
	for initial in ALLOWED_INHERITANCE:
		allowed.append_array(explore_tree(parental_record, initial))
	# Out.print_debug("Duplicated entries: {dup}".format({"dup": find_dup(allowed)}), get_stack())
	for cname in allowed:
		allowed_serializable[cname] = address_record[cname]

func set_serializable():
	# Utilities.ProfilingTools.benchmark(funcref(self, "set_serializable_worker"), \
	# 	[], true)
	set_serializable_worker()
	pass

class Serrializer_V2 extends Reference:

	# Controlled Environment Full-Object Serializer

	const SAFE_CHECK := true
	const SERIALIZER_V2_VER := PoolIntArray([2, 4, 1])
	const MULTITHREADED := false
	enum INSTANCE_TYPE {
		GENERAL_OBJECT,
		NODE,
		RESOURCE,
		SERIALIZABLE,
		CONTAINER,
		DIRECT_VALUE, 
	}

	var original_cfg: Serializable = null
	var final := {}
	var router := {}
	var object_db := {}
	var container_db := {}
	var unserializable_db := {}
	var allowed_serializable := {}

	var iterating: Object = null

	func _init(cfg: Serializable, allowed: Dictionary):
		original_cfg = cfg
		allowed_serializable = allowed
	
	func get_id(curr: Object = null) -> int:
		if curr == null:
			return iterating.get_instance_id()
		return curr.get_instance_id()

	func serialize() -> Dictionary:
		var address := serialize_worker(original_cfg)
		final = {
			"^__serializer_version": SERIALIZER_V2_VER,
			"^__entrance_id": address["^__routed_to"],
			"^__router": router,
			"^__objects": object_db,
			"^__containers": container_db,
			"^__unserializables": unserializable_db,
		}
		return final

	func get_pointer(type := 0, id := 0) -> Dictionary:
		return {
			"^__type": type,
			"^__holder": id,
			"^__dflag": false,
		}

	func get_route(id: int) -> Dictionary:
		return {
			"^__routed_to": id,
		}

	func container_check(obj) -> bool:
		return  obj is Array || obj is Dictionary ||\
				obj is PoolByteArray || obj is PoolColorArray || obj is PoolIntArray ||\
				obj is PoolRealArray || obj is PoolStringArray || obj is PoolVector2Array || obj is PoolVector3Array

	func general_serialization(item):
		if item is Serializable:
			return serialize_worker(item)
		elif item is Resource:
			return s_res(item)
		elif container_check(item):
			return s_container(item)
		else:
			return item

	func s_node(ref: Node) -> Dictionary:
		var obj_id := get_id(ref)
		if obj_id in router:
			return get_route(obj_id)
		var pointer := get_pointer(INSTANCE_TYPE.NODE, obj_id)
		var value := {
			"^__node_name": ref.name,
			"^__node_base_class": ref.get_class(),
			"^__node_path": ref.get_path(),
		}
		router[obj_id] = pointer
		unserializable_db[obj_id] = value
		return get_route(obj_id)

	func s_container(con) -> Dictionary:
		if con is Dictionary:
			return s_dict(con)
		return s_pool(con)

	func s_dict(obj: Dictionary) -> Dictionary:
		var id := -obj.hash()
		if id in router:
			return get_route(id)
		var pointer := get_pointer(INSTANCE_TYPE.CONTAINER, id)
		pointer["^__container_type"] = "hash_map"
		var re = {}
		for key in obj:
			var value = obj[key]
			re[key] = general_serialization(value)
		container_db[id] = re
		router[id] = pointer
		return get_route(id)

	func s_pool(obj) -> Dictionary:
		var copy: Array
		if not obj is Array:
			copy = Array(obj)
		else:
			copy = obj
		var id := -copy.hash()
		if id in router:
			return get_route(id)
		var pointer := get_pointer(INSTANCE_TYPE.CONTAINER, id)
		pointer["^__container_type"] = "pooled"
		var re = []
		if not obj is Array:
			re = obj
		else:
			for item in obj:
				re.append(general_serialization(item))
		container_db[id] = re
		router[id] = pointer
		return get_route(id)

	func s_res(obj: Resource) -> Dictionary:
		var id := obj.get_instance_id()
		if id in router:
			return get_route(id)
		var res_loc := obj.resource_path
		var res_class := obj.get_class()
		var pointer := get_pointer(INSTANCE_TYPE.RESOURCE, id)
		if obj.get_script() != null or res_loc.empty():
			res_loc = ""
			res_class = ""
		var re := {}
		re["^__res_loc"] = res_loc
		re["^__res_class"] = obj.get_class()
		unserializable_db[id] = re
		router[id] = pointer
		return get_route(id)

	# func s_ser(obj: Serializable) -> Dictionary:
	# 	var new_instance := self_instance(obj)
	# 	var new_record: Dictionary = new_instance.serialize()
	# 	router.merge(new_record["^__router"])
	# 	object_db.merge(new_record["^__objects"])
	# 	container_db.merge(new_record["^__containers"])
	# 	unserializable_db.merge(new_record["^__unserializables"])
	# 	return router[new_record["^__entrance_id"]]

	func serialize_worker(curr_cfg: Serializable) -> Dictionary:
		var obj_id := get_id(curr_cfg)
		if obj_id in router:
			return get_route(obj_id)
		if not MULTITHREADED:
			iterating = curr_cfg
		var pointer := get_pointer(INSTANCE_TYPE.SERIALIZABLE, obj_id)
		var real_value := {}
		var cfg_class_name := ""
		if SAFE_CHECK:
			var script_index := allowed_serializable.values().\
				find(curr_cfg.get_script().resource_path)
			if script_index == -1:
				Serializer_AssistClass.prompt_not_allowed(curr_cfg.name)
				return pointer
			cfg_class_name = allowed_serializable.keys()[script_index]
		else:
			cfg_class_name = curr_cfg.name
		pointer["^__ser_base_class"] = curr_cfg.get_class()
		pointer["^__ser_class_name"] = cfg_class_name
		router[obj_id] = pointer
		var re := {}
		for var_name in curr_cfg.property_list:
			var value = curr_cfg.get(var_name)
			re[var_name] = general_serialization(value)
		object_db[obj_id] = re
		return get_route(obj_id)

class Deserializer_V2 extends Reference:

	var original_ser := {}
	var final = null
	var entry := {}
	var router := {}
	var object_db := {}
	var container_db := {}
	var unserializable_db := {}
	var deserialized := {
		"object_db": {},
		"container_db": {},
		"unserializable_db": {},
	}

	var allowed_serializable := {}

	func _init(cfg: Dictionary, allowed: Dictionary):
		original_ser = cfg
		allowed_serializable = allowed

	func reverse_id(id: int):
		
		pass

	func get_pointer(id: int) -> Dictionary:
		return router.get(id, {})

	func deserialize():
		var entrance =		original_ser["^__entrance_id"]
		router =			original_ser["^__router"]
		object_db =			original_ser["^__objects"]
		container_db =		original_ser["^__containers"]
		unserializable_db =	original_ser["^__unserializables"]
		entry = reverse_id(entrance)
		final = deserialize_worker(entry)
		return final

	func general_deserialization(id: int):
		var pointer := get_pointer(id)
		match pointer["^__type"]:
			Serrializer_V2.INSTANCE_TYPE.GENERAL_OBJECT:
				var de = unserializable_db[id]
				deserialized["unserializable_db"][id] = de
				return de
			Serrializer_V2.INSTANCE_TYPE.NODE:
				pass
			Serrializer_V2.INSTANCE_TYPE.RESOURCE:
				pass
			Serrializer_V2.INSTANCE_TYPE.SERIALIZABLE:
				pass
			Serrializer_V2.INSTANCE_TYPE.CONTAINER:
				pass
			Serrializer_V2.INSTANCE_TYPE.DIRECT_VALUE:
				pass
			_:
				return {}

	func deserialize_worker(curr: Dictionary):
		pass

class Serializer_AssistClass extends Reference:

	const CFG_VER := PoolIntArray([1, 3, 0])

	var original_cfg: Serializable = null
	var final := {}
	var allowed_serializable := {}
	var id := 0

	func _init(cfg: Serializable, allowed: Dictionary):
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

	static func prompt_not_allowed(c_name: String):
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

	func serializer_worker(curr_cfg: Serializable) -> Dictionary:
		var re := {}
		var id := get_id()
		var pointer := {"__entry": id}
		final[id] = re
		var script_index := allowed_serializable.values().\
			find(curr_cfg.get_script().resource_path)
		if script_index == -1:
			prompt_not_allowed(curr_cfg.name)
			return pointer
		re["__cfg_base_class"] = curr_cfg.get_class()
		re["__cfg_class_name"] = allowed_serializable.keys()[script_index]
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
		var curr_verr := Serializer_AssistClass.CFG_VER
		for iter in range(0, max_sub_ver):
			if ver[iter] > curr_verr[iter]:
				Out.print_error("Current CFG_VER is lower than given Serializable's", get_stack())
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
		Utilities.TrialTools.try_call(deserialized, "_object_deserialized")
		return deserialized

func _ready():
	set_serializable()
#	for k in allowed_serializable:
#		print("{class}: {path}".format({"class": k, "path": allowed_serializable[k]}))

func serialize(cfg: Serializable, method := 0) -> Dictionary:
	match method:
		0:
			var assist := Serializer_AssistClass.new(cfg, allowed_serializable)
			assist.serialize()
			return assist.final
		1:
			var assist := Serrializer_V2.new(cfg, allowed_serializable)
			return assist.serialize()
		_:
			return {}

func deserialize(ser: Dictionary):
	var assist := Deserializer_AssistClass.new(ser, allowed_serializable)
	assist.deserialize()
	return assist.final

func deserialize_to(ser: Dictionary, target):
	var assist := Deserializer_AssistClass.new(ser, allowed_serializable)
	assist.deserialize_to(target)

func get_name_from_path(path: String) -> String:
	for key in allowed_serializable:
		if allowed_serializable[key] == path:
			return key as String
	return ""
