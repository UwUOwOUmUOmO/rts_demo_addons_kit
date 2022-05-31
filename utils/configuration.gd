extends Resource

class_name Configuration

var name := "Configuration"
var property_list: PoolStringArray = []
var exclusion_list: PoolStringArray = ["property_list", "exclusion_list"]

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
		set(variable, config[variable])
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

func _export() -> Dictionary:
	var re := {}
	for variable in property_list:
		re[variable] = get(variable)
	return re

func export_as_cfg(path := "", pwd := "") -> ConfigFile:
	var cfg := ConfigFile.new()
	var export_dict := _export()
	for val in export_dict:
		cfg.set_value(name, val, export_dict[val])
	if not path.empty():
		if not pwd.empty():
			cfg.save_encrypted_pass(path, pwd)
		else:
			cfg.save(path)
	return cfg
