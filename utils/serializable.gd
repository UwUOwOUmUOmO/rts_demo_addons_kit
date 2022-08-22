extends Resource

class_name Serializable

const CONFIG_VERSION := "1.2.3"

var prop_mutex := Mutex.new()

var name := "Serializable"
var property_list: PoolStringArray = []
var exclusion_list: PoolStringArray = []
var no_deep_scan: PoolStringArray = []

func _init():
	# Create a property list, inheritance can edit exclusion_list
	# to omit volatile variables
	property_list = cleanse_property_list(get_property_list())
	remove_properties(["name", "property_list", "exclusion_list", "no_deep_scan",\
		 "prop_mutex"])
	# OPTIONAL: reset volatile variables
	_reset_volatile()
#	var cfg_server = SingletonManager.fetch("ConfigSerializer")
#	name = cfg_server.get_name_from_path(get_script().resource_path)
	return self

func _to_string():
	var serialized := serialize()
	return str(serialized)

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

func __is_serializable():
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

func copy(from: Serializable) -> bool:
	var full_completion := true
	for component in property_list:
		if not component in from:
			push_warning("Warning: failed to copy property: " + component)
			full_completion = false
			continue
		set(component, from.get(component))
	return full_completion and _data_correction()

func config_duplicate() -> Serializable:
	var dup_res = Resource.new()
	dup_res.set_script(get_script())
	dup_res.copy(self)
	return dup_res

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

func serialize() -> Dictionary:
	return SingletonManager.static_services["ConfigSerializer"].serialize(self)

func deserialize(config: Dictionary):
	SingletonManager.static_services["ConfigSerializer"].deserialize_to(config)

func read_from(path: String, encryption_key := ""):
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
