extends Reference

class_name InRef

var to: Node = null
var desc := ""

var participation: Array = []

func _init(tar: Node):
	to = tar
	to.connect("tree_exiting", self, "target_exiting_handler")

func add_to(name: String):
	IRM.add(self, [name])

func remove_from(name: String):
	IRM.remove(self, [name])

func cut_tie():
	IRM.cut_tie(self)
	to = null

func target_exiting_handler():
	to.disconnect("tree_exiting", self, "target_exiting_handler")
	cut_tie()
