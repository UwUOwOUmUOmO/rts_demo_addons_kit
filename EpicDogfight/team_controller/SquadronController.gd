extends HierachialController

class_name SquadronController

enum ASSIGNMENT_METHOD { SIMPLE }

signal __enemy_squadron_changed(controller, new_enemy)

var ref_team_name := ""

var squad_name := ""
var squad_uid := 0
var current_assignment_method: int = ASSIGNMENT_METHOD.SIMPLE

var is_ready := false
var board_lock := Mutex.new()
var enemy_squadron = null setget set_senemy
var enemy_vehicles := {}
var assignment_board := {}
var detected_bogeys := []
var vehicles := {}
var _ref: InRef = null

var gp_cluster: ProcessorsCluster = null
var edicts_pool: EdictsStateMachine = null

func _ready():
	_ref = InRef.new(self)
	IRM.add(_ref, ["squadron_controllers", ref_team_name])
	connect("__enemy_squadron_changed", self, "enemy_change_handler")
	edicts_pool = EdictsStateMachine.new()
	gp_cluster.add_processor(edicts_pool)
	edicts_pool.host = self
	is_ready = true

func add_vehicle(v_name: String, v: Spatial):
	vehicles[name] = v
	if v.has_signal("__target_defeated"):
		v.connect("__target_defeated", self, "target_defeat_handler")

func reset_assignment_board():
	assignment_board = {}
	for enemy_callsign in enemy_vehicles:
		assignment_board[enemy_callsign] = 0

func enemy_check(enemy) -> bool:
	var re := true
	if not is_instance_valid(enemy):
		re = false
	elif enemy.hp <= 0.0:
		re = false
	return re

func get_least_attended_enemy():
	# Only used for simple_reassign_all_targets()
	# Least attended count start out at infinity
	var least_attended_count := INF
	var least_attended_enemy = null
	var re = null
	for enemy_callsign in assignment_board:
		var enemy_attendants_count = assignment_board[enemy_callsign]
		var enemy = enemy_vehicles[enemy_callsign]
		# Check for Node validity
		if not enemy_check(enemy):
			assignment_board.erase(enemy_callsign)
			continue
		if enemy_attendants_count == 0:
			least_attended_enemy = enemy
			break
		# If current attendants count is lesser than previous's
		# which start out at infinity, reassign least attended enemy
		elif enemy_attendants_count < least_attended_count:
				least_attended_enemy = enemy

	return least_attended_enemy
	
func set_senemy(new_enemy):
	if new_enemy == enemy_squadron:
		return
	enemy_squadron = new_enemy
	enemy_vehicles = enemy_squadron.vehicles
	reset_assignment_board()
	emit_signal("__enemy_squadron_changed", self, enemy_squadron)

func enemy_change_handler(_con, _enemy):
	simple_reassign_all_targets()

func simple_reassign_all_targets():
	# Simple target reassignment
	# WARNING: VERY SIMPLE
	var v_count  := vehicles.size()
	var ev_count := enemy_vehicles.size()
	var v_klist := vehicles.keys()
	var current_vehicle = null
	var ev_klist := enemy_vehicles.keys()
	var current_ev = null
	var vehicle_iter := 0
	var enemy_iter := 0
	var invalid_enemy := false
	while true:
		if (vehicle_iter >= v_count) or \
		   (enemy_iter >= ev_count):
				break
		# Separate allies and enemies iterators cause
		# some enemies might be invalid
		var vehicle_callsign = v_klist[vehicle_iter]
		current_vehicle = vehicles[vehicle_callsign]
		current_ev = enemy_vehicles[ev_klist[enemy_iter]]
		if not enemy_check(current_ev):
			invalid_enemy = true
			enemy_iter += 1
			continue
		current_vehicle.target = current_ev
		assignment_board[vehicle_callsign] = 1 + \
			assignment_board[vehicle_callsign]
		# Increment the iterators
		vehicle_iter += 1
		enemy_iter += 1

func target_defeat_handler(controller):
	if current_assignment_method == ASSIGNMENT_METHOD.SIMPLE:
		var new_enemy = get_least_attended_enemy()
		if new_enemy != null:
			controller.target = new_enemy

func bogey_handler(bogey):
	if not bogey in enemy_vehicles.values():
		detected_bogeys.append(bogey)
		Out.print_debug("New hostile detected")
