extends Resource

class_name Configuration

var name := "Configuration"
var property_list: PoolStringArray = []

func _init():
	property_list = cleanse_property_list(get_property_list())

func cleanse_property_list(list: Array) -> PoolStringArray:
	var new_list: PoolStringArray= []
	var clear := false
	for content in list:
		var prop: Dictionary = content
		if prop["name"] == "property_list":
			continue
		if clear:
			new_list.push_back(prop["name"])
			continue
		if prop["name"] == "Script Variables":
			clear = true
	return new_list

func _import(config: Dictionary) -> void:
	for variable in property_list:
		if not config.has(variable):
			push_warning("Warning: failed to import property: " + variable)
			print_stack()
			continue
		set(variable, config[variable])

func _export() -> Dictionary:
	var re := {}
	for variable in property_list:
		re[variable] = get(variable)
	return re

func export_as_cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	var export_dict := _export()
	for val in export_dict:
		cfg.set_value(name, val, export_dict[val])
	return cfg
