extends Resource

class_name LevelResource, "../icons/level_res_icon.png"

export(String) var scene = ""
export(PoolStringArray) var critical_assets_list = []
export(PoolStringArray) var on_demand_assets_list = []

export(PackedScene) var loading_scene_primary = null
