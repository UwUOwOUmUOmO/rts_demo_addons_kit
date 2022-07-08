extends Node

const TC_UID_START_NUM := 20000
const MAX_TEAM_COUNT := 63

signal __new_team_created(team)

var clearance := true

var team_count := 0
var tc_entry: Node
var tc_curr_id := TC_UID_START_NUM
var tc_binary := 1
var tc_lock := Mutex.new()

class TC_AssistClass extends Reference:
	enum RELATIONSHIP {
		ALLIES		= 1,
		UNION		= 2,
		HOSTILES	= 4,
	}

	static func make_groups_bicode(team_list: Array) -> int:
		var re := 0
		for team in team_list:
			re += team.team_bicode
		return re

	static func make_entry(team_list: Array, type := 1) -> String:
		var entry_code := make_groups_bicode(team_list)
		if type == RELATIONSHIP.HOSTILES:
			return "hostiles_" + str(entry_code)
		elif type == RELATIONSHIP.UNION:
			return "union_" + str(entry_code)
		return "allies_" + str(entry_code)

	static func make_unions(team_list: Array) -> String:
		var entry_name := make_entry(team_list, RELATIONSHIP.UNION)
		for team in team_list:
			IRM.add(team._ref, [entry_name])
			team.team_relationship["allies"].append(entry_name)
		return entry_name

	static func make_allies(team1: TeamController, team2: TeamController) -> String:
		var entry_name := make_entry([team1, team2], RELATIONSHIP.ALLIES)
		if IRM.exists(entry_name):
			return entry_name
		IRM.add(team1._ref, [entry_name])
		IRM.add(team2._ref, [entry_name])
		team1.team_relationship["allies"].append(entry_name)
		team2.team_relationship["allies"].append(entry_name)
		return entry_name

	static func make_hostiles(team1: TeamController, team2: TeamController):
		var entry_name := make_entry([team1, team2], RELATIONSHIP.HOSTILES)
		if IRM.exists(entry_name):
			return entry_name
		IRM.add(team1._ref, [entry_name])
		IRM.add(team2._ref, [entry_name])
		team1.team_relationship["hostiles"].append(entry_name)
		team2.team_relationship["hostiles"].append(entry_name)
		return entry_name

	static func make_neutral(team1: TeamController, team2: TeamController):
		var team_list := [team1, team2]
		var entry1 := make_entry(team_list, RELATIONSHIP.ALLIES)
		var entry2 := make_entry(team_list, RELATIONSHIP.HOSTILES)

		IRM.remove(team1._ref, [entry1])
		IRM.remove(team2._ref, [entry1])
		IRM.remove(team1._ref, [entry2])
		IRM.remove(team2._ref, [entry2])

		team1.team_relationship["allies"].erase(entry1)
		team2.team_relationship["allies"].erase(entry1)
		team1.team_relationship["hostiles"].erase(entry2)
		team2.team_relationship["hostiles"].erase(entry2)

func _ready():
	connect("__new_team_created", self, "new_team_handler")
	# Setup squad controllers entry
	tc_entry = Node.new()
	tc_entry.name = "SquaCon_entry"
	# Singletons are allowed to directly do this
	add_child(tc_entry)

func spawn_team(team_name: String) -> TeamController:
	if not clearance:
		return null
	var new_team := TeamController.new()
	new_team.name = team_name
	new_team.team_name = team_name
	tc_lock.lock()
	new_team.team_uid = tc_curr_id
	new_team.team_bicode = tc_binary
	tc_binary *= 2
	tc_curr_id += 1
	team_count += 1
	tc_lock.unlock()
	tc_entry.call_deferred("add_child", new_team)
	emit_signal("__new_team_created", new_team)
	return new_team

func decommision_team(team_name: String):
	var team := tc_entry.get_node_or_null(team_name)
	if not is_instance_valid(team):
		Out.print_error("Team not exist/is queuing for deletion: " + team_name, \
			get_stack())
		return
	team.queue_free()

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

func get_team(inp):
	if inp is int:
		return get_team_by_id(inp)
	elif inp is String:
		return get_team_by_name(inp)
	Out.print_error("Invalid input for get_team: " + str(inp), \
		get_stack())

func get_tc() -> Array:
	return tc_entry.get_children()

func new_team_handler(_team):
	if team_count >= 63:
		clearance = false
		Out.print_warning("Max team count reached {count}, team creation is no longer possile" \
			.format({"count": MAX_TEAM_COUNT}), get_stack())
