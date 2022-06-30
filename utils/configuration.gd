extends Resource

class_name Configuration

const CONFIG_VERSION := "1.2.2"

var prop_mutex := Mutex.new()

var name := "Configuration"
var property_list: PoolStringArray = []
var exclusion_list: PoolStringArray = []
var no_deep_scan: PoolStringArray = []

func _init():
	# Create a property list, inheritance can edit exclusion_list
	# to omit volatile variables
	exclusion_list.append_array(\
		["name", "property_list", "exclusion_list", "no_deep_scan",\
		 "prop_mutex"])
	property_list = cleanse_property_list(get_property_list())
	# OPTIONAL: reset volatile variables
	_reset_volatile()
	return self

func remove_property(what: String):
	prop_mutex.lock()
	# var size := property_list.size()
	# for i in range(0, size):
	# 	if property_list[i] == what:
	# 		property_list.remove(i)
	# 		break
	var arr_tmp := Array(property_list)
	arr_tmp.erase(what)
	property_list = arr_tmp
	prop_mutex.unlock()

func remove_properties(what: PoolStringArray):
	prop_mutex.lock()
	var arr_tmp := Array(property_list)
	for c in what:
		arr_tmp.erase(c)
	property_list = arr_tmp
	prop_mutex.unlock()

func _reset_volatile():
	pass

func _data_correction() -> bool:
	# Check for variables correctness
	return true

func __is_config():
	# Dumb way to get by cyclic reference
	return true

func cleanse_property_list(list: Array) -> PoolStringArray:
	var new_list: PoolStringArray= []
	var clear := false
	for content in list:
		var prop: Dictionary = content
		
		if prop["name"] in exclusion_list:
			continue
		if clear:
			new_list.push_back(prop["name"])
			continue
		if prop["name"] == "Script Variables":
			clear = true
	return new_list

static func try_instance_config(path: String):
	# Try to instance a Configuration class object
	# If provided script is invalid, return null
	if not ResourceLoader.exists(path):
		return null
	var script: Script = load(path)
	var instance := Resource.new()
	instance.set_script(script)
	return instance


static func resource_dererialize(dict: Dictionary) -> Resource:
	var class_n: String = dict["__base_class_name"]
	var res_loc: String = dict["__base_resource_loc"]
	if not ClassDB.can_instance(class_n):
		Out.print_error("Can't instance class: " + class_n,\
			get_stack())
		return null
	var res = ResourceLoader.load(res_loc, class_n)
	if res == null:
		Out.print_error("Can't load resource at: " + res_loc,\
			get_stack())
	return res

static func config_deserialize(dict: Dictionary) -> Resource:
	var subres_script_path = dict["__config_class_path"]
	if Out.err_fail_condition(not subres_script_path is String,\
		"subres_script_path is not String", get_stack()):
			return null
	var new_subres = try_instance_config(subres_script_path)
	if new_subres != null:
		new_subres.deserialize(dict)
		return new_subres
	else:
		Out.print_error("Can't instance script with path: "\
			+ subres_script_path,\
			get_stack())
		return null

static func dictionary_deserialize(dict: Dictionary):
	# If dict has "__config_class_path" then try to instance
	# Else if dict has "__base_resource_loc" then try to load Resource
	# Else recursively scan the original dict
	if dict.has("__config_class_path"):
		return config_deserialize(dict)
	elif dict.has("__base_resource_loc"):
		return resource_dererialize(dict)
	else:
		var re := {}
		for key in dict:
			var value = dict[key]
			if value is Dictionary:
				re[key] = dictionary_deserialize(value)
			elif value is Array:
				re[key] = array_deserialize(value)
			else:
				re[key] = value
		return re

static func array_deserialize(arr: Array) -> Array:
	var re := []
	for value in arr:
		if value is Array:
			re.append(array_deserialize(value))
		elif value is Dictionary:
			re.append(dictionary_deserialize(value))
		else:
			re.append(value)
	return re

static func resource_serialize(res: Resource) -> Dictionary:
	var subres := {}
	var loc: String = res.resource_path
	if not res.resource_path.empty():
		var err := ResourceSaver.save(loc, res)
		Out.error_check(err, get_stack())
		subres["__base_resource_loc"] = loc
		subres["__base_class_name"] = res.get_class()
	return subres

static func subres_serialize(subres: Resource) -> Dictionary:
	if subres.has_method("__is_config"):
		return subres.serialize()
	else:
		return resource_serialize(subres)

static func dictionary_serialize(dict: Dictionary) -> Dictionary:
	var re := {}
	var has_serializable := false
	for key in dict:
		var value = dict[key]
		if value is Resource:
			has_serializable = true
			re[key] = subres_serialize(value)
		elif value is Dictionary:
			re[key] = dictionary_serialize(value)
		elif value is Array:
			re[key] = array_serialize(value)
		else:
			re[key] = value
	if not has_serializable:
		return dict
	return re

static func array_serialize(arr: Array) -> Array:
	var re := []
	var has_serializable := false
	for value in arr:
		if value is Resource:
			has_serializable = true
			re.append(subres_serialize(value))
		elif value is Array:
			re.append(array_serialize(value))
		elif value is Dictionary:
			re.append(dictionary_serialize(value))
		else:
			re.append(value)
	if not has_serializable:
		return arr
	return re

func copy(from: Configuration) -> bool:
	var full_completion := true
	for component in property_list:
		if not component in from:
			push_warning("Warning: failed to copy property: " + component)
			full_completion = false
			continue
		set(component, from.get(component))
	return full_completion and _data_correction()

func version_greater(target: String):
	var target_sliced := target.rsplit(".", true, 2)
	var current_sliced := CONFIG_VERSION.rsplit(".", true, 2)
	if target_sliced.size() != 3:
		Out.print_error("Failed to check target's CONFIG_VERSION",\
			get_stack())
		return false
	for iter in range(0, 3):
		# Check for version
		# Major > Minor > Patch
		if int(target_sliced[iter]) > int(current_sliced[iter]):
			return true
	return false

func deserialize(config: Dictionary) -> bool:
	var full_completion := true
	if "__cfgver" in config:
		var target_ver: String = config["__cfgver"]
		if version_greater(target_ver):
			Out.print_warning("Target's CONFIG_VER is greater than"\
				+ " current CONFIG_VER",\
				get_stack())
	for variable in property_list:
		if not config.has(variable):
			push_warning("Warning: failed to import property: " + variable)
			full_completion = false
			continue
		var value = config[variable]
		var cured = value
		if not variable in no_deep_scan:
			if value is Dictionary:
				cured = dictionary_deserialize(value)
			elif value is Array:
				cured = array_deserialize(value)
		set(variable, cured)
	return full_completion and _data_correction()

func serialize(replace_subres := true) -> Dictionary:
	var re := {
		"__cfgver": CONFIG_VERSION,
		"__config_class_path": get_script().resource_path
	}
	for variable in property_list:
		var component = get(variable)
		if not replace_subres or not component is Reference:
			# Dictionary may contain Configurations
			# If current key does not appear in no scan list, scan it
			if not variable in no_deep_scan:
				if component is Dictionary:
					re[variable] = dictionary_serialize(component)
					continue
				elif component is Array:
					re[variable] = array_serialize(component)
					continue
			re[variable] = component
		else:
			# Nodes are volatile, can't be serialized
			if component is Node:
				continue
			# If component is Configuration, serialize it
			elif component.has_method("__is_config"):
				re[variable] = component.serialize()
				continue
			# If component is non-Configuration Resource,
			# Use a different method to serialize
			elif component is Resource:
				var res_serialized := resource_serialize(component)
				if not res_serialized.empty():
					re[variable] = res_serialized
					continue
			# Fall back: just assign the original value lol
			re[variable] = component
	return re

func read_from(path: String, encryption_key := "") -> int:
	var file := File.new()
	var err: int
	if encryption_key.empty():
		err = file.open(path, File.READ)
	else:
		err = file.open_encrypted_with_pass(path, File.READ, encryption_key)
	if err != OK:
		Out.print_error("No.({ecode}): Can't open file at: {path}"\
			.format({"ecode": err, "path": path}), get_stack())
	else:
		var dict: Dictionary = file.get_var()
		file.close()
		deserialize(dict)
	return err

func save_as(path: String, encryption_key := "") -> int:
	var file := File.new()
	var err: int
	if encryption_key.empty():
		err = file.open(path, File.WRITE)
	else:
		err = file.open_encrypted_with_pass(path, File.WRITE, encryption_key)
	if err != OK:
		Out.print_error("No.({ecode}): Can't open file at: {path}"\
			.format({"ecode": err, "path": path}), get_stack())
	else:
		var exported := serialize()
		file.store_var(exported)
		file.close()
	return err
