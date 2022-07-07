extends HierachialController

class_name TeamController

var team_name := ""
var team_uid := 0
var squadrons := {}

var is_ready := false
var _ref: InRef = null

func _ready():
	_ref = InRef.new(self)
	_ref.add_to("team_controllers")
	is_ready = true

func _exit_tree():
	_ref.cut_tie()
	_ref = null
