extends AirCombatant

class_name NAFB_Standalone

const DEFAULT_AFBCFG := preload("res://addons/Vehicular/configs/default_afbncfg.tres")

# System settings
# var STANDALONE_STATE_AUTOMATON: bool = ProjectSettings.get_setting("game/standalone_state_automaton")  setget set_forbidden

# Configurations
var is_halted := false
var allow_gravity := false setget set_gravity

# Important variables
var state_automaton: StateAutomaton = null
var pda: PushdownAutomaton = null
var states := {} setget , get_states

# Volatile
var drag := 0.0
var downward_speed := 0.0
var roll_queue := 0.0

var db_last_cs := -1.0

# Next Advanced Fighter Brain Standalone State
class NAFBSS_Planner extends State:

	const ENGINE_CHECK_AT := 1.5
	const ENGINE_SPEED_THRESHOLD := 0.01
	# const RANGE_THRESHOLD := 1.0

	signal destination_arrived(brain)
	
	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null

	var engine_check_timer := 0.0

	var deadzone_squared := 0.0
	var sd_est_sq := 0.0001		# Slow down estimation
	var cta_sq := 0.0			# Cut throttle at squared
	var oe_sq := 0.0			# Orbit error
	var displacable_speed := 0.0
	var ds_squared := 0.0
	var control_locked := false

	# var location_check := Vector3.ZERO

	func _init():
		state_name = "NAFBSS_Planner"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		automaton = with
		displacable_speed = afb_cfg.get_area_deccel(0.0, afb_cfg.max_deccel_time)
		ds_squared = displacable_speed * displacable_speed

	func set_moving_status(s: bool):
		afb.isMoving = s
		# location_check = afb.global_transform.origin
		# engine_check_timer = 0.0
		if s == false: emit_signal("destination_arrived", afb)

	func reset_status():
		var d_s: float = afb_cfg.deadzone
		d_s *= d_s
		oe_sq = afb_cfg.orbitError
		oe_sq *= oe_sq
		deadzone_squared = d_s
		control_locked = false
		automaton.blackboard_set("skip_throttle", false)

	func bake_next_des(with: StateAutomaton):
		afb.db_last_cs = afb.currentSpeed
		if afb.inheritedSpeed > 0.0:
			afb.set_speed(afb.inheritedSpeed)
			afb.inheritedSpeed = 0.0
		var d_squared: float = afb.distance_squared
		var sa_sq: float = afb_cfg.slowingAt
		sa_sq *= sa_sq
		sd_est_sq = sa_sq * d_squared
		control_locked = false
		set_moving_status(true)
		with.blackboard_set("skip_throttle", false)

	func cut_throttle():
		afb.throttle = 0.0
		afb.speedPercentage = 0.0
		control_locked = true
		automaton.blackboard_set("skip_throttle", true)

	func _start(with: StateAutomaton):
		update(with)
		reset_status()

	func _poll(with: StateAutomaton):
		var delta := with.get_delta()
		engine_check_timer += delta
		# if engine_check_timer > ENGINE_CHECK_AT:
		# 	pass
		# 	set_moving_status(false)
		# 	return "__next"
		if control_locked: 
			if afb.currentSpeed < ENGINE_SPEED_THRESHOLD:
				set_moving_status(false)
			return "__next"
		if not afb.isMoving: return "__stop"
		var d_squared: float = afb.distance_squared
		var cs_squared: float = afb.currentSpeed
		cs_squared *= cs_squared
		if d_squared <= deadzone_squared or \
			d_squared < min(ds_squared, cs_squared):
			cut_throttle()
		else:
			afb.throttle = 1.0
		with.blackboard_set("accel_update", false)

	func _finalize(with: StateAutomaton):
		pass

class NAFBSS_Engine extends State:

	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null
	
	var accel_timer := 0.0

	func _init():
		state_name = "NAFBSS_Engine"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		automaton = with

	func _start(with: StateAutomaton):
		update(with)
		automaton.blackboard_set("accel_update", false)

	func _poll(with: StateAutomaton):
		var curr: float = afb.currentSpeed
		if curr == 0.0: return "__next"
		var delta := with.get_delta()
		var accel_update: bool = automaton.blackboard_get("accel_update")
		var speed_change := 0.0
		if accel_update: accel_timer = 0.0
		else:
			accel_timer += delta
			speed_change = afb_cfg.get_area_deccel(accel_timer - delta, accel_timer)
			curr = clamp(curr - speed_change, 0.0, afb_cfg.max_speed * 1.5)
			if curr == 0.0:
				pass
		afb.set_speed(curr)
		return "__next"

	func _finalize(with: StateAutomaton):
		pass

class NAFBSS_Throttle extends State:

	const DRAG_CONSTANT := 0.23

	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null


	var speed_change := 0.0
	var accu_lost_rate := 0.4
	var allowed_speed := 0.0
	var theoretical_speed := 0.0
	var accel_timer := 0.0
	# 0: Accel
	# 1: Deaccel
	var last_accel_mode := 1

	func _init():
		state_name = "NAFBSS_Throttle"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		accu_lost_rate = afb_cfg.accel_accumulation_lost_rate * afb_cfg.accel_graph.range
		automaton = with

	func _start(with: StateAutomaton):
		update(with)

	func measurement_setup():
		allowed_speed = afb.throttle * afb_cfg.max_speed
		if allowed_speed != 0.0:
			afb.speedPercentage = afb.currentSpeed / allowed_speed
		else:
			afb.speedPercentage = 0.0

	func calculate_speed(delta: float):
		var curr: float = afb.currentSpeed
		if curr > allowed_speed:
			accel_timer = clamp(accel_timer - (accu_lost_rate * delta), \
				0.0, afb_cfg.accel_graph.range * 1.5)
#			accel_timer = 0.0
			theoretical_speed = curr
		accel_timer += delta
		speed_change = afb_cfg.get_area_accel(accel_timer - delta, accel_timer)
		var speed_delta: float = abs(curr - allowed_speed)
		theoretical_speed = clamp(curr + abs(min(speed_change, speed_delta)), 0.0, allowed_speed * 2.0)

	func process_drag():
		var drag_force := theoretical_speed
		drag_force = 0.0
		# drag_force *= afb.drag * DRAG_CONSTANT
		if afb.currentSpeed > theoretical_speed:
			Out.print_debug("Here", get_stack())
#			afb.db_last_cs = -1.0
		afb.set_speed(clamp(theoretical_speed - drag_force, 0.0, INF))

	func _poll(with: StateAutomaton):
		var delta := with.get_delta()
		if with.blackboard_get("skip_throttle"):
			accel_timer = clamp(accel_timer - (accu_lost_rate * delta), \
				0.0, afb_cfg.accel_graph.range * 1.5)
#			accel_timer = 0.0
			return
		measurement_setup()
		calculate_speed(delta)
		process_drag()
		# enforce_throttle(delta)
		theoretical_speed = 0.0
		with.blackboard_set("accel_update", true)
		return "__next"

	func _finalize(with: StateAutomaton):
		pass

class NAFBSS_Gravity extends State:

	const GRAVITATIONAL_CONSTANT = 9.8

	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null

	func _init():
		state_name = "NAFBSS_Gravity"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		automaton = with

	func _start(with: StateAutomaton):
		update(with)

	func _poll(with: StateAutomaton):
		if not afb.allow_gravity: return "__next"
		var delta := with.get_delta()
		afb.downward_speed += GRAVITATIONAL_CONSTANT * delta
		return "__next"

	func _finalize(with: StateAutomaton):
		pass

class NAFBSS_Climb extends State:
	
	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null

	func _init():
		state_name = "NAFBSS_Climb"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		automaton = with

	func _start(with: StateAutomaton):
		update(with)

	func _poll(with: StateAutomaton):
		return "__next"

	func _finalize(with: StateAutomaton):
		pass

class NAFBSS_Steer extends State:

	const STEER_SUPPOSED_THRESHOLD				:= deg2rad(360.0)
	const AERODYNAMICS_PARTIAL_SUBSIDARY		:= 0.4
	const MINIMUM_DRAG							:= 0.000001

	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null

	var lost_rate := 0.01
	var turn_timer := 0.0
	var distipation := 0.1745329
	var ampli := 0.0
	var allowed := 0.0

	func _init():
		state_name = "NAFBSS_Steer"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		ampli = afb_cfg.turn_rate_amplification
		distipation = deg2rad(afb_cfg.turn_rate_accu_distipation)
		lost_rate = afb_cfg.turn_accumulation_lost_rate * afb_cfg.turn_graph.range
		automaton = with

	func _start(with: StateAutomaton):
		update(with)

	func calculate_turn_rate(delta: float) -> float:
		# var min_turn_rate: float = afb_cfg.turnRate
		# var max_turn_rate: float = afb_cfg.maxTurnRate
		# var allowed_turn: float = lerp(max_turn_rate, min_turn_rate, \
		# 	clamp(afb.speedPercentage, 0.0, 1.0))
		var sampled := afb_cfg.get_area_turn(turn_timer - delta, turn_timer)
		var allowed_turn: float = lerp(sampled * ampli, sampled, \
			clamp(afb.speedPercentage, 0.0, 1.0))

		return allowed_turn

	func calculate_drag(turn_rate: float, delta: float) -> float:
		var steer_rps := turn_rate / delta
		return steer_rps / STEER_SUPPOSED_THRESHOLD

	func manual_lerp_steer(to: Vector3, amount: float):
		var global_pos: Vector3 = afb.global_transform.origin
		# var looking_at: Vector3 = -afb.global_transform.basis.z
		if to == global_pos: return
		var wtransform: Transform = afb.global_transform.\
			looking_at(Vector3(to.x,global_pos.y,to.z),Vector3.UP)
		var wrotation: Quat = afb.global_transform.basis.get_rotation_quat().slerp(Quat(wtransform.basis),\
			amount)
		afb.global_transform = Transform(Basis(wrotation), afb.global_transform.origin)

	func timer_distipate(delta: float):
		var pos: Vector3 = afb.global_transform.origin
		var fwd: Vector3 = -afb.global_transform.basis.z
		var des: Vector3 = afb.current_destination
		var tar: Vector3 = pos.direction_to(des)
		# if pos == des or fwd.angle_to(tar) <= distipation or afb.currentSpeed <= 0.01:
		if pos == des or fwd.angle_to(tar) <= distipation or not afb.isMoving:
			var change := lost_rate * delta
			turn_timer = clamp(turn_timer - change, 0.0, afb_cfg.turn_graph.range * 1.5)

	func _poll(with: StateAutomaton):
		var delta := with.get_delta()
		timer_distipate(delta)
		turn_timer += delta
		var max_amount := calculate_turn_rate(delta)
		allowed = max_amount
		var drag := calculate_drag(max_amount, delta)
		drag = (drag * (1.0 - AERODYNAMICS_PARTIAL_SUBSIDARY)) + \
			(AERODYNAMICS_PARTIAL_SUBSIDARY * (1.0 - afb_cfg.aerodynamic))
		drag = clamp(drag, MINIMUM_DRAG, INF)
		afb.drag = drag
		manual_lerp_steer(afb.current_destination, max_amount)
		return "__next"

	func _finalize(with: StateAutomaton):
		pass

class NAFBSS_Roll extends State:

	var afb = null
	var afb_cfg: AFBNewConfiguration = null
	var automaton: StateAutomaton = null

	var last_yaw := 0.0

	func _init():
		state_name = "NAFBSS_Roll"

	func update(with: StateAutomaton):
		afb = with.client; afb_cfg = afb._vehicle_config;
		automaton = with

	func _start(with: StateAutomaton):
		update(with)

	func get_yaw() -> float:
		return (afb.global_transform as Transform).\
			basis.get_euler().y

	static func shitty_roll(target: Spatial, amount: float):
		target.rotation.z = clamp(amount, -PI / 2.0, PI / 2.0)
		pass

	static func children_roll(target: Spatial, amount: float):
		# return shitty_roll(target, amount)
		var size := target.get_child_count()
		if target is Spatial and size > 0:
			# var curr_z: float = target.rotation.z
			# target.rotation.z = clamp(curr_z + amount, -PI, PI)
			# var new_amount: float = target.get_child(0).rotation.z + amount
			# new_amount = clamp(new_amount, -PI, PI)
			var iter = 0
			while iter < size:
				var curr = target.get_child(iter)
				if curr is Spatial: curr.rotation.z = amount
				iter += 1

	func _poll(with: StateAutomaton):
		var delta := with.get_delta()
		var current_yaw := get_yaw()
		var yaw_delta := current_yaw - last_yaw
		var roll_justified: float = yaw_delta * afb_cfg.turn_to_roll_rate
		# var curr_roll := (afb.global_transform as Transform).\
		# 	basis.get_euler().z
		# var roll_rps := yaw_delta / delta
		# var roll_justified: float = roll_rps * afb_cfg.rollAmplifier
		var max_roll_angle: float = afb_cfg.maxRollAngle
		roll_justified = clamp(roll_justified, -max_roll_angle, max_roll_angle)
		# children_roll(afb, roll_justified)
		afb.roll_queue = roll_justified
		last_yaw = current_yaw

#		if afb.currentSpeed < afb.db_last_cs:
#			Out.print_debug("Here", get_stack())
#			afb.db_last_cs = -1.0

		return "__next"

	func _finalize(with: StateAutomaton):
		pass

func set_forbidden(_a): return

func set_gravity(g: bool):
	allow_gravity = g
	downward_speed = 0.0

func get_states() -> Dictionary:
	if pda == null: return {}
	return pda.get_all_states()

func des_arrived_handler(_b):
	# change_machine_state(false)
	pass

func change_machine_state(s := true):
	if s: emit_signal("__started_moving", state_automaton)

func set_multides(des: PoolVector3Array) -> void:
	.set_multides(des)
	change_machine_state(true)

func add_destination(des: Vector3) -> void:
	.add_destination(des)

func set_course(des: Vector3) -> void:
	current_destination = des
	change_machine_state(true)

func _init():
	._init()
	set_config(DEFAULT_AFBCFG.config_duplicate())

func state_automaton_init():
	state_automaton = StateAutomaton.new()
	
	pda = PushdownAutomaton.new()
	# pda.add_state(NAFBSS_RollNormalize.new())
	pda.add_state(NAFBSS_Gravity.new())
	pda.add_state(NAFBSS_Engine.new())
	pda.add_state(NAFBSS_Planner.new())
	pda.add_state(NAFBSS_Throttle.new())
	pda.add_state(NAFBSS_Climb.new())
	pda.add_state(NAFBSS_Steer.new())
	pda.add_state(NAFBSS_Roll.new())

	state_automaton.pda = pda

	var planner := pda.get_state_by_name("NAFBSS_Planner")
	planner.connect("destination_arrived", self, "des_arrived_handler")
	connect("__started_moving", planner, "bake_next_des")
	state_automaton.client = self
	state_automaton.boot()

func _ready():
	._ready()
	# if USE_THREAD_DISPATCHER:
	# 	NodeDispatcher.add_node(self)

func _enter_tree():
	state_automaton_init()

func _exit_tree():
	state_automaton.finalize()
	if pda != null:
		pda.terminated = true
	state_automaton.terminated = true
	state_automaton = null
	pda = null

func compute(delta: float):
	state_automaton.poll(delta)

func enforce_all():
	# Enforce roll
	var size := get_child_count()
	if size > 0:
		# var curr_z: float = target.rotation.z
		# target.rotation.z = clamp(curr_z + amount, -PI, PI)
		# var new_amount: float = target.get_child(0).rotation.z + amount
		# new_amount = clamp(new_amount, -PI, PI)
		var iter = 0
		while iter < size:
			var curr = get_child(iter)
			if curr is Spatial: curr.rotation.z = roll_queue
			iter += 1
	# Enforce translation
	if not isMoving: return
	var dir: Vector3 = -global_transform.basis.z
	dir *= currentSpeed
	dir += Vector3.DOWN * downward_speed
	move_and_slide(dir, Vector3.UP)

func set_speed(new_speed: float):
	if (currentSpeed / clamp(new_speed, 0.001, INF)) > 100.0 and new_speed != 0.0:
		pass
	currentSpeed = new_speed

func _physics_process(delta):
	if _use_physics_process:
		compute(delta)
	enforce_all()

func _process(delta):
	if not _use_physics_process:
		compute(delta)
