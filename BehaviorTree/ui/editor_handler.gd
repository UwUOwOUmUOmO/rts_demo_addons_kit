tool
extends Node

const BT_LISR := {
	"Behavior Tree": 0,
	
}
const BT_SCENE_LIST := [
	[preload("nodes/node_BehaviorTree.tscn"), null]
]

onready var parent := get_parent()
onready var workspace := parent\
	.get_node("MainContainer/Splitter/Workspace")
onready var node_browser := parent\
	.get_node("MainContainer/Splitter/NodeBrowser")

var active_resource: BehaviorTreeResource = null
var node_list := []

var last_active_node = null
var proceed := false

func _ready():
	node_browser.clear()
	for item in BT_LISR:
		node_browser.add_item(item)

func _process(delta):
	if proceed:
		compute(delta)

func compute(delta: float):
	pass

func redraw():
	pass

func resource_check():
	if not is_instance_valid(active_resource.behavior_tree_node):
		active_resource.behavior_tree_node = BehaviorTree.new()

func __editor_ready_handler(isReady: bool):
	proceed = isReady
	active_resource = parent.active_file
	resource_check()
	redraw()

func _on_NodeBrowser_item_activated(index):
	print("Instancing")
	var bt_instance = BT_SCENE_LIST[index][0].instance()
	workspace.add_child(bt_instance)
	bt_instance.offset += Vector2(40.0, 40.0)
