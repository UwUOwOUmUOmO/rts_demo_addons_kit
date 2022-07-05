extends Reference

class_name InRef

const DEFAULT_GC_INTERVAL := 1.0

var tree: SceneTree = null
var to: Node = null
var desc := ""

var interval := DEFAULT_GC_INTERVAL
var participation: Array = []

func _init(b: Node, a: SceneTree = null, enable_gc := false):
	tree = a
	to = b
	if enable_gc:
		gc()

func add_to(name: String):
	IRM.add(self, [name])

func remove_from(name: String):
	IRM.remove(self, [name])

func cut_tie():
	IRM.cut_tie(self)
	to = null

func gc():
	if tree == null:
		return
	while true:
		var inter := interval
		if inter <= 0.0:
			inter = DEFAULT_GC_INTERVAL
		yield(tree.create_timer(inter), "timeout")
		
		if not is_instance_valid(to):
			to = null
			cut_tie()
			break
