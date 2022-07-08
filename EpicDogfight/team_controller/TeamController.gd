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

func _ready():
	_ref = InRef.new(self)
	# Team UID might not be assign in time
	while team_uid == 0:
		yield(get_tree(), "idle_frame")
	ref_team_name = "cteam_" + team_name + str(team_uid)
	IRM.add(_ref, ["team_controllers", ref_team_name])
	is_ready = true

func _exit_tree():
	_ref.cut_tie()
	_ref = null

func spawn_squadron(squad_name: String, _type = SquadronController):
	var new_squad = _type.new()
	new_squad.squad_name = squad_name
	new_squad.ref_team_name = ref_team_name
	sc_lock.lock()
	new_squad.squad_uid = sc_curr_id
	squadrons[sc_curr_id] = new_squad
	sc_curr_id += 1
	sc_lock.unlock()
	call_deferred("add_child", new_squad)
	emit_signal("__new_squadron_created", new_squad)
	return new_squad

func remove_squadron(squad_name: String):
	var squad := get_node_or_null(squad_name)
	if not is_instance_valid(squad):
		Out.print_error("Squad not exists/is queuing for deletion: " + squad_name, \
			get_stack())
		return
	squad.queue_free()