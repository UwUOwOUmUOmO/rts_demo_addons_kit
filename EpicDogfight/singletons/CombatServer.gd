extends Node

const TC_UID_START_NUM := 20000

var tc_entry: Node
var tc_curr_id := TC_UID_START_NUM
var tc_lock := Mutex.new()

func _ready():
	# Setup squad controllers entry
	tc_entry = Node.new()
	tc_entry.name = "SquaCon_entry"
	# Singletons are allowed to directly do this
	add_child(tc_entry)

func spawn_team(team_name: String) -> TeamController:
	var new_team := TeamController.new()
	new_team.name = team_name
	new_team.team_name = team_name
	tc_entry.call_deferred("add_child", new_team)
	tc_lock.lock()
	new_team.team_uid = tc_curr_id
	tc_curr_id += 1
	tc_lock.unlock()
	return new_team

func decommision_team_(team_name: String):
	var team = tc_entry.get_node_or_null(team_name)
	if not is_instance_valid(team):
		Out.print_error("Team not exist: " + team_name, \
			get_stack())
		return
	call_deferred("remove_child", team)

func get_team_by_name(team_name: String):
	var children := tc_entry.get_children()
	for tc in children:
		if tc.team_name == team_name:
			return tc
	return null

func get_team_by_id(id: int):
	if id < TC_UID_START_NUM:
		return null
	var children := tc_entry.get_children()
	for tc in children:
		if tc.team_uid == id:
			return tc
	return null

func get_tc() -> Array:
	return tc_entry.get_children()
