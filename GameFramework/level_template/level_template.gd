extends Node

class_name LevelTemplate

const LOCAL_IRM_SCRIPT := preload("res://addons/GameFramework/com/local_irm.gd")

onready var scenes_holder := $MainScenes
onready var peripherals_pool := $ControllersSwarm
onready var singletons_pool := $SingletonsSwarm
var local_irm: Node = null

func _ready():
	var lirmn := Node.new()
	lirmn.name = "LocalIRM"
	lirmn.set_script(LOCAL_IRM_SCRIPT)
	singletons_pool.add_instanced_singleton(lirmn)
	local_irm = lirmn

func free_all_scenes():
	var old_levels := scenes_holder.get_children()
	for c in old_levels:
		c.queue_free()

func add_scene(new_scene: Node, defered := true, remove_old := true):
	if remove_old:
		free_all_scenes()
	if defered:
		scenes_holder.call_deferred("add_child", new_scene)
	else:
		scenes_holder.add_child(new_scene)

func remove_scene(s_name := ""):
	if s_name.empty():
		free_all_scenes()
	var c := get_node_or_null(s_name)
	if c:
		c.queue_free()

func add_peripheral(con: Node, auto_clean := -1.0):
	peripherals_pool.add_peripheral(con, auto_clean)
