class_name BehaviorTree, "res://addons/behavior_tree/icons/bt.svg"
extends Node

# This is your main node. Put one of these at the root of the scene and start adding BTNodes.
# A Behavior Tree only accepts ONE entry point (so one child).

const SELF_SIGNALS := {
	"child_entered_tree": "child_enter_handler",
	"child_exiting_tree": "child_exit_handler",
}

export(bool) var is_active: bool = false setget set_active
export(NodePath) var _blackboard
export(int, "Idle", "Physics") var sync_mode
export(bool) var debug = false

var tick_result
var agent: Node = null
var bt_root = null setget set_root

onready var blackboard = get_node(_blackboard) as Blackboard

func _init():
	# Utilities.SignalTools.connect_from(self, self, SELF_SIGNALS)
	pass

func _ready() -> void:
	# bt_root.propagate_call("connect", ["abort_tree", self, "abort"])
	start()

func set_process_state():
	set_process((not bt_root == null) and is_active and sync_mode == 0)
	set_physics_process((not bt_root == null) and is_active \
		and sync_mode == 1)

func set_root(r: BTNode):
	bt_root = r
	set_process_state()

func set_active(a: bool):
	is_active = a
	set_process_state()

# UNUSED
func child_enter_handler(node):
	if not node.has_signal("abort_tree"):
		return
	Utilities.SignalTools.connect_from(node, self, SELF_SIGNALS)
	node.connect("abort_tree", self, "abort")

# UNUSED
func child_exit_handler(node):
	if not node.has_signal("abort_tree"):
		return
	Utilities.SignalTools.disconnect_from(node, self, SELF_SIGNALS)
	node.disconnect("abort_tree", self, "abort")

func compute(is_physics := false):
	if debug:
		print()

	tick_result = bt_root.tick(agent, blackboard)

	if tick_result is GDScriptFunctionState:
		if is_physics:
			set_physics_process(false)
		else:
			set_process(false)
		yield(tick_result, "completed")
		if is_physics:
			set_physics_process(true)
		else:
			set_process(true)

func _process(_delta: float) -> void:
	compute()

func _physics_process(_delta: float) -> void:
	compute(true)

# func set_host(host):
# 	Utilities.TrialTools.try_set(blackboard, "host", host)

# Internal: Set up if we are using process or physics_process for the behavior tree
func start() -> void:
	set_process_state()
	# if not is_active:
	# 	return

	# match sync_mode:
	# 	0:
	# 		set_physics_process(false)
	# 		set_process(true)
	# 	1:
	# 		set_process(false)
	# 		set_physics_process(true)

# Public: Set the tree to inactive when a abort_tree signal is sent from bt_root
func abort() -> void:
	set_active(false)
