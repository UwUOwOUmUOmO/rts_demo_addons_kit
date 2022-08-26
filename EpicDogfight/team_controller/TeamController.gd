extends HierachialController

class_name TeamController

const SC_UID_START_NUM := 21000

signal __new_squadron_created(squad)

var team_name := ""
var team_uid := 0
var team_bicode := 1
var team_relationship := {
	"allies": [],
	"hostiles": [],
}
var squadrons := {}

var is_ready := false
var ref_team_name := ""
var sc_curr_id := SC_UID_START_NUM
var _ref: InRef = null
var sc_lock := Mutex.new()

var gp_cluster: ProcessorsCluster = null
var squadrons_cluster: ProcessorsCluster = null
var edicts_pool: EdictsStateMachine = null

func _ready():
	_ref = InRef.new(self)
	# Team UID might not be assign in time
	while team_uid == 0:
		yield(get_tree(), "idle_frame")
	ref_team_name = "cteam_" + team_name + str(team_uid)
	IRM.add(_ref, ["team_controllers", ref_team_name])
	edicts_pool = EdictsStateMachine.new()
	gp_cluster.add_processor(edicts_pool)
	edicts_pool.host = self
	squadrons_cluster = SingletonManager.fetch("ProcessorsSwarm")\
		.add_cluster("SquaConGPCluster", true)
	is_ready = true

func spawn_squadron(squad_name: String, _type = SquadronController):
	var new_squad = _type.new()
	new_squad.squad_name = squad_name
	new_squad.ref_team_name = ref_team_name
	sc_lock.lock()
	new_squad.squad_uid = sc_curr_id
	new_squad.gp_cluster = squadrons_cluster
	squadrons[sc_curr_id] = new_squad
	sc_curr_id += 1
	sc_lock.unlock()
	call_deferred("add_child", new_squad)
	new_squad.set_deferred("owner", self)
	emit_signal("__new_squadron_created", new_squad)
	return new_squad

func remove_squadron(squad_name: String):
	var squad := get_node_or_null(squad_name)
	# if not is_instance_valid(squad):
	# 	Out.print_error("Squad not exists/is queuing for deletion: " + squad_name, \
	# 		get_stack())
	# 	return
	Toolkits.TrialTools.try_call(squad, "queue_free")