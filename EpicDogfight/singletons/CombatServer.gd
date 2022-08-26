extends Node

class_name CombatServer

const TC_UID_START_NUM := 20000
const MAX_TEAM_COUNT := 63

signal __new_team_created(team)

var clearance := true

var team_count := 0
var tc_entry: Node
var tc_curr_id := TC_UID_START_NUM
var tc_binary := 1
var tc_lock := Mutex.new()

var teams_cluster: ProcessorsCluster = null

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

class CombatMiddleman extends Reference:
	static func test_call():
		print("HelloWorld")
	# Support functions
	static func resistant_calculate(res: PoolRealArray, mixture: int) -> float:
		var total_match := 0
		var mixed := 0.0
		# Calculate the average resistant of each warhead's type (blendable)
		if mixture & DamageModifiersConfiguration.WARHEAD_TYPE.PRESSURIZED:
			total_match += 1
			mixed += res[1]
		if mixture & DamageModifiersConfiguration.WARHEAD_TYPE.SELF_IMPLODED:
			total_match += 1
			mixed += res[2]
		if mixture & DamageModifiersConfiguration.WARHEAD_TYPE.FOWARD_CLUSTERED:
			total_match += 1
			mixed += res[3]
		if mixture & DamageModifiersConfiguration.WARHEAD_TYPE.ARMOR_PIERCING:
			total_match += 1
			mixed += res[4]
		if mixture & DamageModifiersConfiguration.WARHEAD_TYPE.ENERGY:
			total_match += 1
			mixed += res[5]
		if total_match <= 0:
			return 1.0
		var avg: float = mixed / float(total_match)
		# Return inverted average resistant
		return clamp(1.0 / avg, 0.0001, INF)

	static func warhead_dmg_calculate(mod: DamageModifiersConfiguration) \
			-> float:
		var type := mod.warhead_type
		var mixed := 1.0
		if type == HullProfile.ARMOR_TYPE.NA:
			mixed *= mod.none
			return mixed
		if type & HullProfile.ARMOR_TYPE.SPACED:
			mixed *= mod.spaced
		if type & HullProfile.ARMOR_TYPE.PLATED:
			mixed *= mod.plated
		if type & HullProfile.ARMOR_TYPE.COMPOSITE:
			mixed *= mod.composite
		if type & HullProfile.ARMOR_TYPE.STRUCTURE:
			mixed *= mod.structure
		if type & HullProfile.ARMOR_TYPE.FORT:
			mixed *= mod.fort
		return clamp(mixed, 0.0, INF)

	static func effector_calculate(effector_list: Array) -> float:
		# TODO: Implement Armor Effectors
		return 1.0

	# Main functions
	static func add_hull_effector(target, eff: Effector):
		# To be implemented
		if target is Combatant:
			Toolkits.TrialTools.try_append(target, "_vehicle_config.hullProfile.effector_pool", eff)
		elif target is HullProfile:
			(target as HullProfile).effector_pool

	static func damage(request: DamageRequest):
		var hull_profile: HullProfile = Toolkits.TrialTools.try_get(request.damage_target, \
			"_vehicle_config.hullProfile")
		
		if hull_profile == null:
			return
		var hull_resistant_mod := 1.0
		var warhead_dmg_mod := 1.0
		if request.damage_mod != null:
			hull_resistant_mod = resistant_calculate(hull_profile.resistant, request.damage_mod.warhead_type)
			warhead_dmg_mod = warhead_dmg_calculate(request.damage_mod)
		var effectors_mod := effector_calculate(hull_profile.effector_pool)
		var computed_damage := request.base_damage * \
			(hull_resistant_mod * warhead_dmg_mod * effectors_mod)
		hull_profile.damage(computed_damage)

func _ready():
	connect("__new_team_created", self, "new_team_handler")
	# Setup squad controllers entry
	tc_entry = Node.new()
	tc_entry.name = "SquaCon_entry"
	# Singletons are allowed to directly do this
	add_child(tc_entry)
	tc_entry.owner = self
	teams_cluster = SingletonManager.fetch("ProcessorsSwarm")\
		.add_cluster("TeamConGPCluster", true)

func spawn_team(team_name: String) -> TeamController:
	if not clearance:
		return null
	var new_team := TeamController.new()
	new_team.name = team_name
	new_team.team_name = team_name
	tc_lock.lock()
	new_team.team_uid = tc_curr_id
	new_team.team_bicode = tc_binary
	new_team.gp_cluster = teams_cluster
	tc_binary *= 2
	tc_curr_id += 1
	team_count += 1
	tc_lock.unlock()
	tc_entry.call_deferred("add_child", new_team)
	new_team.set_deferred("owner", self)
	emit_signal("__new_team_created", new_team)
	return new_team

func decommision_team(team_name: String):
	var team := tc_entry.get_node_or_null(team_name)
	# if not is_instance_valid(team):
	# 	Out.print_error("Team not exist/is queuing for deletion: " + team_name, \
	# 		get_stack())
	# 	return
	Toolkits.TrialTools.try_call(team, "queue_free")

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
