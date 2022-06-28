extends HierachialController

class_name SquadronController

enum ASSIGNMENT_METHOD { SIMPLE }

signal enemy_squadron_changed(controller, new_enemy)

var current_assignment_method: int = ASSIGNMENT_METHOD.SIMPLE

var enemy_squadron = null setget set_senemy
var enemy_vehicles := {}
var assignment_board := {}

var vehicles := {}

func _init():
    ._init()
    connect("enemy_squadron_changed", self, "enemy_change_handler")

func add_vehicle(v_name: String, v: Spatial):
    vehicles[name] = v
    v.connect("__target_defeated", self, "target_defeat_handler")

func reset_assignment_board():
    assignment_board = {}
    for enemy_callsign in enemy_vehicles:
        assignment_board[enemy_callsign] = 0

func get_least_attended_enemy():
    # Only used for simple_reassign_all_targets()
    # Least attended count start out at infinity
    var least_attended_count := INF
    var least_attended_enemy = null
    for enemy_callsign in assignment_board:
        var enemy_attendants_count = assignment_board[enemy_callsign]
        var enemy = enemy_vehicles[enemy_callsign]
        # If current enemy has no attendant, return immediately
        if enemy_attendants_count == 0:
            return enemy
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
    emit_signal("enemy_squadron_changed", self, enemy_squadron)

func enemy_change_handler(_con, _enemy):
    simple_reassign_all_targets()

func simple_reassign_all_targets():
    # Simple target reassignment
    # WARNING: VERY SIMPLE
    var v_count := vehicles.size()
    var v_klist := vehicles.keys()
    var current_vehicle = null
    var ev_klist := enemy_vehicles.keys()
    var current_ev = null
    for iter in range(0, v_count):
        var vehicle_callsign = v_klist[iter]
        current_vehicle = vehicles[vehicle_callsign]
        current_ev = enemy_vehicles[ev_klist[iter]]
        current_vehicle.target = current_ev
        assignment_board[vehicle_callsign] = 1 + \
            assignment_board[vehicle_callsign]

func target_defeat_handler(controller):
    if current_assignment_method == ASSIGNMENT_METHOD.SIMPLE:
        var new_enemy = get_least_attended_enemy()
        controller.target = new_enemy
