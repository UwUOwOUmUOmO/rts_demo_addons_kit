extends Serializable

class_name LevelConfiguration, "icons/level_res_icon.png"

# Persistent
export(String) var scene_path := ""
export(String) var loading_scene_path := ""
export(PoolStringArray) var preload_list: PoolStringArray = []
export(Array) var singletons_list := []
 
func _init():
	name = "LevelConfiguration"
