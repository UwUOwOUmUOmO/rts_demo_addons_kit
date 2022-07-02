extends Configuration

class_name LevelConfiguration, "icons/level_res_icon.png"

# Persistent
export(String) var scene_path := ""
export(PoolStringArray) var preload_list := []
export(String) var loading_scene_path := ""


func _init():
    ._init()
    name = "LevelConfiguration"
