extends Resource

class_name Configuration

var name := "Configuration"
var property_list: PoolStringArray = []
var exclusion_list: PoolStringArray =\
	["name", "property_list", "exclusion_list", "custom_class_list"]
var custom_class_list := []

func _init():
	property_list = cleanse_property_list(get_property_list())

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

func try_instance_config(name: String):
	if custom_class_list.empty():
		custom_class_list = ProjectSettings\
			.get_setting("_global_script_classes")
	for item in custom_class_list:
		if item["class"] == name:
			var script: Script = load(item["path"])
			var instance := Resource.new()
			instance.set_script(script)
			return instance
	return null

func dictionary_handler(dict: Dictionary):
	if dict.has("__config_class_name"):
		var subres_class_name: String = dict["__config_class_name"]
		var new_subres = try_instance_config(subres_class_name)
		if new_subres != null:
			new_subres._import(dict)
			return new_subres
		else:
			push_error("Can't instance class with name: " + subres_class_name)
			return null
	else:
		return dict

func copy(from: Configuration) -> bool:
	var full_completion := true
	for component in property_list:
		if not component in from:
			push_warning("Warning: failed to copy property: " + component)
			print_stack()
			full_completion = false
			continue
		set(component, from.get(component))
	return full_completion

func _import(config: Dictionary) -> bool:
	var full_completion := true
	for variable in property_list:
		if not config.has(variable):
			push_warning("Warning: failed to import property: " + variable)
			print_stack()
			full_completion = false
			continue
		var value = config[variable]
		var cured = value
		if value is Dictionary:
			cured = dictionary_handler(value)
		set(variable, cured)
	return full_completion

func import_from_cfg(cfg: ConfigFile) -> bool:
	var full_completion := true
	for component in property_list:
		var raw = cfg.get_value(name, component)
		if not is_instance_valid(raw):
			push_warning("Warning: failed to import property: " + component)
			print_stack()
			full_completion = false
			continue
		set(component, raw)
	return full_completion

func _export(for_cfg := false) -> Dictionary:
	var re := {}
	for variable in property_list:
		var component = get(variable)
		if for_cfg:
			re[variable] = component
		else:
			if variable == "dvConfig":
				pass
			if not component is Reference:
				re[variable] = component
			elif component.has_method("cleanse_property_list"):
				var subres: Dictionary = component._export()
				var subres_name: String = component.name
				subres["__config_class_name"] = subres_name
				re[variable] = subres
			else:
				re[variable] = component
	return re

func export_as_cfg(path := "", pwd := "") -> ConfigFile:
	var cfg := ConfigFile.new()
	var export_dict := _export(true)
	for val in export_dict:
		cfg.set_value(name, val, export_dict[val])
	if not path.empty():
		if not pwd.empty():
			cfg.save_encrypted_pass(path, pwd)
		else:
			cfg.save(path)
	return cfg
