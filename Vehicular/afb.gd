extends AirCombatant

class_name AdvancedFighterBrain

const DEFAULT_AFBCFG := preload("res://addons/Vehicular/configs/default_afbcfg.tres")

onready var  fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta

# Persistent
var states_auto_init := true
var is_halted := false
var state_machine: StateMachine = null
var allow_gravity := false setget set_gravity
var states := {}

# Volatile
var drag := 0.0
var downward_speed := 0.0

class AFBSM_Planner extends StateSingular:

	const ZONE_PADDING_SQUARED := 7.0

	signal destination_arrived(brain)

	var afb = null
	var afb_cfg: AFBConfiguration = null

	var deadzone_squared := 0.0
	var sd_est_sq := 0.0001		# Slow down estimation
	var cta_sq := 0.0			# Cut throttle at squared
	var oe_sq := 0.0			# Orbit error
	var control_locked := false

	func _init():
		name = "AFBSM_Planner"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func reset_status():
		var d_s: float = afb_cfg.deadzone
		d_s *= d_s
		oe_sq = afb_cfg.orbitError
		oe_sq *= oe_sq
		deadzone_squared = d_s
		control_locked = false
		set_moving_status(afb.isMoving)
		blackboard_set("skip_throttle", false)

	func _boot():
		afb = current_machine.host
		update()
		reset_status()

	func bake_next_des():
		if afb.inheritedSpeed > 0.0:
			afb.currentSpeed = afb.inheritedSpeed
			afb.inheritedSpeed = 0.0
		var d_squared: float = afb.distance_squared
		var sa_sq: float = afb_cfg.slowingAt
		sa_sq *= sa_sq
		sd_est_sq = sa_sq * d_squared
		control_locked = false
		set_moving_status(true)
		blackboard_set("skip_throttle", false)

	func set_moving_status(s: bool):
		afb.isMoving = s
		set_exclusive(not s)

	func cut_throttle():
		afb.throttle = 0.0
		control_locked = true
		blackboard_set("skip_throttle", true)

	func _compute(delta: float):
		if exclusive or control_locked:
			return null
		var d_squared: float = afb.distance_squared
		var slowing_time: float = afb_cfg.slowingTime
		var accel: float = (afb_cfg.decceleration)
		var velocity: float = afb.currentSpeed
		cta_sq = (velocity * slowing_time) + (0.5 * accel * slowing_time * slowing_time)
		cta_sq = clamp(cta_sq, 0.0, INF)
		cta_sq *= cta_sq
		if d_squared <= deadzone_squared:
			cut_throttle()
		if d_squared <= cta_sq:
			cut_throttle()
		else:
			afb.throttle = 1.0
		blackboard_set("accel_update", false)

class AFBSM_Engine extends StateSingular:

	const ACCEL_ACCU_LOST_RATE := 0.4

	var afb = null
	var afb_cfg: AFBConfiguration = null
	var accel_timer := 0.0
	var deccel_total := 0.0
	var curr_st := 0.0

	func _init():
		name = "AFBSM_Engine"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config
		bake_deccel_time()

	func bake_deccel_time():
		curr_st = afb_cfg.slowingTime
		deccel_total = afb_cfg.get_area_deccel(0.0, curr_st)

	func _boot():
		afb = current_machine.host
		blackboard_set("accel_update", false)
		update()
		# bake_deccel_time()

	func get_equalizer(delta: float) -> float:
		var accel: float = afb_cfg.decceleration
		var normalized_accel := accel * delta
		return normalized_accel

	func equalize_speed(delta: float) -> float:
		var equalized := get_equalizer(accel_timer)
		# var equalized: float = afb_cfg.decceleration * delta
		var curr: float = afb.currentSpeed
		curr = clamp(curr + equalized, 0.0, INF)
		afb.currentSpeed = curr
		return curr

	func _compute(delta: float):
		var accel_update: bool = blackboard_get("accel_update")
		var curr := equalize_speed(delta)
		if accel_update:
			# accel_timer = clamp(accel_timer - (accel_timer * ACCEL_ACCU_LOST_RATE * delta), \
			# 	0.0, INF)
			accel_timer = 0.0
			curr = afb.currentSpeed
		else:
			accel_timer += delta
		var fwd_vec: Vector3 = -afb.global_transform.basis.z
		var movement := fwd_vec * curr
		afb.move_and_slide(movement)

class AFBSM_Throttle extends StateSingular:

	const DRAG_CONSTANT := 0.23
	const ACCEL_ACCU_LOST_RATE := 0.4
	const INTEGRAL_SAMPLES_PER_SECONDS := 120.0

	var afb = null
	var afb_cfg: AFBConfiguration = null
	var allowed_speed := 0.0
	var theoretical_speed := 0.0
	var accel_timer := 0.0
	# 0: Accel
	# 1: Deaccel
	var last_accel_mode := 1

	func _init():
		name = "AFBSM_Throttle"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func _boot():
		afb = current_machine.host
		update()

	func measurement_setup():
		allowed_speed = afb.throttle * afb_cfg.maxSpeed
		if allowed_speed != 0.0:
			afb.speedPercentage = afb.currentSpeed / allowed_speed
		else:
			afb.speedPercentage = 0.0

	# func calculate_speed(delta: float):
	# 	var curr: float = afb.currentSpeed
	# 	var speed_mod := 0.0
	# 	var speed_change := 0.0
	# 	var speed_delta: float = abs(curr - allowed_speed)
	# 	var curr_accel_mode: int
	# 	if curr > allowed_speed:
	# 		speed_mod = afb_cfg.decceleration
	# 		curr_accel_mode = 1
	# 	else:
	# 		speed_mod = afb_cfg.acceleration
	# 		curr_accel_mode = 0
	# 	speed_change = speed_mod * delta
	# 	# ----------------------------------------------
	# 	# if curr_accel_mode != last_accel_mode:
	# 	# 	accel_timer = 0.0
	# 	# last_accel_mode = curr_accel_mode
	# 	# accel_timer += delta
	# 	# speed_change = speed_mod * accel_timer
	# 	# ----------------------------------------------
	# 	speed_change = min(speed_delta, speed_change)
	# 	theoretical_speed = clamp(curr + speed_change, 0.0, INF)

	func calculate_speed(delta: float):
		var curr: float = afb.currentSpeed
		if curr > allowed_speed:
			accel_timer = clamp(accel_timer - (accel_timer * ACCEL_ACCU_LOST_RATE * delta), \
				0.0, INF)
			return
		accel_timer += delta
		# var speed_mod: float = afb_cfg.acceleration
		# var speed_change := speed_mod * accel_timer
		var cfg: AFBConfiguration = afb_cfg
		var raw_ssize := INTEGRAL_SAMPLES_PER_SECONDS * delta
		var samples: int = max(1, int(raw_ssize))
		# var speed_change: float = cfg.sample_accel(accel_timer)
		# speed_change -= cfg.sample_accel(accel_timer - delta)
		var speed_change := cfg.get_area_accel(accel_timer - delta, accel_timer, samples)
		var speed_delta: float = abs(curr - allowed_speed)
		theoretical_speed = clamp(curr + min(speed_change, speed_delta), 0.0, INF)

	func process_drag():
		var drag_force := theoretical_speed
		drag_force = 0.0
		drag_force *= afb.drag * DRAG_CONSTANT
		afb.currentSpeed = clamp(theoretical_speed - drag_force, 0.0, INF)

	func enforce_throttle(delta: float):
		var fwd_vec: Vector3 = -afb.global_transform.basis.z
		var movement: Vector3 = fwd_vec * afb.currentSpeed
		afb.move_and_slide(movement, Vector3.UP)
		# afb.global_translate(movement * delta)

	func _compute(delta: float):
		if blackboard_get("skip_throttle"):
			return
		measurement_setup()
		calculate_speed(delta)
		process_drag()
		# enforce_throttle(delta)
		theoretical_speed = 0.0
		blackboard_set("accel_update", true)

class AFBSM_Gravity extends StateSingular:

	const GRAVITATIONAL_CONSTANT = 9.8

	var afb = null
	var afb_cfg: AFBConfiguration = null

	func _init():
		name = "AFBSM_Gravity"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func _boot():
		afb = current_machine.host
		update()

	func _compute(delta: float):
		if not afb.allow_gravity:
			return
		afb.downward_speed += GRAVITATIONAL_CONSTANT * delta
		afb.move_and_slide(Vector3(0.0, -afb.downward_speed, 0.0))

class AFBSM_Climb extends StateSingular:

	var afb = null
	var afb_cfg: AFBConfiguration = null

	func _init():
		name = "AFBSM_Climb"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func _boot():
		afb = current_machine.host
		update()

	func _compute(_delta: float):
		pass

class AFBSM_Steer extends StateSingular:

	const STEER_SUPPOSED_THRESHOLD				:= deg2rad(360.0)
	const AERODYNAMICS_PARTIAL_SUBSIDARY		:= 0.4
	const MINIMUM_DRAG							:= 0.000001

	var afb = null
	var afb_cfg: AFBConfiguration = null
	var allowed := 0.0
	var called := 0
	var physics_call := 0

	func _init():
		name = "AFBSM_Steer"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func _boot():
		afb = current_machine.host
		update()
		pfps_test()

	func calculate_turn_rate() -> float:
		var min_turn_rate: float = afb_cfg.turnRate
		var max_turn_rate: float = afb_cfg.maxTurnRate
		var allowed_turn: float = lerp(max_turn_rate, min_turn_rate, \
			clamp(afb.speedPercentage, 0.0, 1.0))

		return allowed_turn

	func calculate_drag(turn_rate: float, delta: float) -> float:
		var steer_rps := turn_rate / delta
		return steer_rps / STEER_SUPPOSED_THRESHOLD

	func manual_lerp_steer(to: Vector3, amount: float):
		var global_pos: Vector3 = afb.global_transform.origin
		var target_pos := to
		var rotation_speed := amount
		var wtransform: Transform = afb.global_transform.\
			looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3.UP)
		var wrotation := Quat(afb.global_transform.basis).slerp(Quat(wtransform.basis),\
			rotation_speed)

		afb.global_transform = Transform(Basis(wrotation), afb.global_transform.origin)

	func pfps_test():
		while true:
			yield(Out.timer(1.0), "timeout")
			physics_call = called
			called = 0

	func _compute(delta: float):
		var max_amount := calculate_turn_rate()
		allowed = max_amount
		var drag := calculate_drag(max_amount, delta)
		drag = (drag * (1.0 - AERODYNAMICS_PARTIAL_SUBSIDARY)) + \
			(AERODYNAMICS_PARTIAL_SUBSIDARY * (1.0 - afb_cfg.aerodynamic))
		drag = clamp(drag, MINIMUM_DRAG, INF)
		afb.drag = drag
		manual_lerp_steer(afb.current_destination, max_amount)
		called += 1

class AFBSM_Roll extends StateSingular:

	var afb = null
	var afb_cfg: AFBConfiguration = null
	var last_yaw := 0.0

	func _init():
		name = "AFBSM_Roll"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func get_yaw() -> float:
		return (afb.global_transform as Transform).\
			basis.get_euler().y

	func _boot():
		afb = current_machine.host
		last_yaw = get_yaw()
		update()

	static func children_roll(target: Node, amount: float):
		var children := target.get_children()
		for child in children:
			if child is Spatial:
				child.rotation.z = amount

	func _compute(delta: float):
		var current_yaw := get_yaw()

		var yaw_delta := current_yaw - last_yaw
		var roll_rps := yaw_delta / delta
		var roll_justified: float = roll_rps * afb_cfg.rollAmplifier
		var max_roll_angle: float = afb_cfg.maxRollAngle
		roll_justified = clamp(roll_justified, -max_roll_angle, max_roll_angle)
		children_roll(afb, roll_justified)

		last_yaw = current_yaw

class AFBSM_RollNormalize extends StateSingular:

	var afb = null
	var afb_cfg: AFBConfiguration = null
	var last_yaw := 0.0

	func _init():
		name = "AFBSM_RollNormalize"
		state_name = name

	func update():
		afb_cfg = afb._vehicle_config

	func _boot():
		afb = current_machine.host
		update()

	func _compute(delta: float):
		var roll_justified: float = afb_cfg.rollNormalizationSpeed * delta
		AFBSM_Roll.children_roll(afb, roll_justified)

func _init():
	._init()
	set_config(DEFAULT_AFBCFG)
	state_machine = StateMachine.new()
	state_machine.host = self
	state_machine.enforcer = self

func _ready():
	._ready()
	if states_auto_init:
		init_states()

func update_states():
	Utilities.TrialTools.try_propagate(states, "update")

func init_states():
#	if states != {}:
#		return
	var rn := AFBSM_RollNormalize.new()
	var gr := AFBSM_Gravity.new()
	var eq := AFBSM_Engine.new()
	var pl := AFBSM_Planner.new()
	var th := AFBSM_Throttle.new()
	var cl := AFBSM_Climb.new()
	var st := AFBSM_Steer.new()
	var ro := AFBSM_Roll.new()

	states = {
		rn.state_name: rn,
		gr.state_name: gr,
		eq.state_name: eq,
		pl.state_name: pl,
		th.state_name: th,
		cl.state_name: cl,
		st.state_name: st,
		ro.state_name: ro,
	}
	state_machine.mass_push(states.values())
	pl.connect("destination_arrived", self, "des_arrived_handler")

func des_arrived_handler(_b):
	# change_machine_state(false)
	pass

func set_gravity(g: bool):
	allow_gravity = g
	downward_speed = 0.0
	state_machine.states_pool["AFBSM_Gravity"].suspended = not g

func set_multides(des: PoolVector3Array) -> void:
	.set_multides(des)
	change_machine_state(true)

func add_destination(des: Vector3) -> void:
	.add_destination(des)
#	change_machine_state(true)

func set_course(des: Vector3) -> void:
	current_destination = des
	change_machine_state(true)

func change_machine_state(s := true):
	# state_machine.is_paused = s
	if s:
		state_machine.states_pool["AFBSM_Planner"].bake_next_des()

func compute(delta: float):
	if is_halted:
		return
	state_machine._compute(delta)

func _physics_process(delta):
	if _use_physics_process:
		compute(delta)

func _process(delta):
	if not _use_physics_process:
		compute(delta)
