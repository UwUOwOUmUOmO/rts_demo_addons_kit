extends AirCombatant

class_name AdvancedFighterBrain

onready var  fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta

# Persistent
var state_machine: StateMachine = null
var allow_gravity := false setget set_gravity

# Volatile
var drag := 0.0
var downward_speed := 0.0

class AFBSM_Planner extends StateSingular:

	signal destination_arrived(brain)

	var afb = null
	var deadzone_squared := 0.0

	func _init():
		name = "AFBSM_Planner"
		state_name = name

	func _boot():
		afb = current_machine.host
		var d_s: float = afb._vehicle_config.deadzone
		d_s *= d_s
		deadzone_squared = d_s

	func bake_next_des():
		exclusive = false

	func _compute(delta: float):
		if exclusive:
			return null
		var d_squared: float = afb.distance_squared
		if d_squared <= deadzone_squared:
			exclusive = true
		# else:
		# 	afb.throttle = 1.0

class AFBSM_Throttle extends StateSingular:

	const DRAG_CONSTANT := 1.8

	var afb = null
	var allowed_speed := 0.0
	var theoretical_speed := 0.0

	func _init():
		name = "AFBSM_Throttle"
		state_name = name

	func _boot():
		afb = current_machine.host

	func measurement_setup():
		allowed_speed = afb.throttle * afb._vehicle_config.maxSpeed
		if afb.allowedSpeed != 0.0:
			afb.speedPercentage = afb.currentSpeed / afb.allowedSpeed
		else:
			afb.speedPercentage = 0.0

	func calculate_speed(delta: float):
		var curr: float = afb.currentSpeed
		var speed_mod := 0.0
		var speed_change := 0.0
		var clamp_min := 0.0
		if curr > allowed_speed:
			speed_mod = afb._vehicle_config.deccelaration
		else:
			speed_mod = afb._vehicle_config.acceleration
		speed_change = speed_mod * delta
		theoretical_speed = clamp(curr + speed_change, clamp_min, afb._vehicle_config.maxSpeed)

	func process_drag():
		var drag_force := theoretical_speed
		drag_force *= afb.drag * DRAG_CONSTANT
		afb.currentSpeed = clamp(theoretical_speed - drag_force, 0.0, afb._vehicle_config.maxSpeed)

	func enforce_throttle():
		var fwd_vec: Vector3 = -afb.global_transform.basis.z
		var movement: Vector3 = fwd_vec * afb.currentSpeed
		afb.move_and_slide(movement, Vector3.UP)

	func _compute(delta: float):
		measurement_setup()
		calculate_speed(delta)
		process_drag()
		enforce_throttle()

class AFBSM_Gravity extends StateSingular:

	const GRAVITATIONAL_CONSTANT = 9.8

	var afb = null

	func _init():
		name = "AFBSM_Gravity"
		state_name = name

	func _boot():
		afb = current_machine.host

	func _compute(delta: float):
		afb.downward_speed += GRAVITATIONAL_CONSTANT * delta
		afb.move_and_slide(Vector3(0.0, -afb.downward_speed, 0.0))

class AFBSM_Climb extends StateSingular:

	var afb = null

	func _init():
		name = "AFBSM_Climb"
		state_name = name

	func _boot():
		afb = current_machine.host

	func _compute(_delta: float):
		pass

class AFBSM_Steer extends StateSingular:

	const STEER_SUPPOSED_THRESHOLD				:= deg2rad(180.0)
	const AERODYNAMICS_PARTIAL_SUBSIDARY		:= 0.4
	const MINIMUM_DRAG							:= 0.000001

	var afb = null

	func _init():
		name = "AFBSM_Steer"
		state_name = name

	func _boot():
		afb = current_machine.host

	func calculate_turn_rate() -> float:
		var min_turn_rate: float = afb._vehicle_config.turnRate
		var max_turn_rate: float = afb._vehicle_config.maxTurnRate
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

	func _compute(delta: float):
		var max_amount := calculate_turn_rate()
		var drag := calculate_drag(max_amount, delta)
		drag = (drag * (1.0 - AERODYNAMICS_PARTIAL_SUBSIDARY)) + \
			(AERODYNAMICS_PARTIAL_SUBSIDARY * (1.0 - afb._vehicle_config.aerodynamic))
		drag = clamp(drag, MINIMUM_DRAG, INF)
		afb.drag = drag
		manual_lerp_steer(afb.current_destination, max_amount)

class AFBSM_Roll extends StateSingular:

	var afb = null
	var last_yaw := 0.0

	func _init():
		name = "AFBSM_Roll"
		state_name = name

	func get_yaw() -> float:
		return (afb.global_transform as Transform).\
			basis.get_euler().y

	func _boot():
		afb = current_machine.host
		last_yaw = get_yaw()

	static func children_roll(target: Node, amount: float):
		var children := target.get_children()
		for child in children:
			if child is Spatial:
				child.rotation.z = amount

	func _compute(delta: float):
		var current_yaw := get_yaw()

		var yaw_delta := current_yaw - last_yaw
		var roll_rps := yaw_delta / delta
		var roll_justified: float = roll_rps * afb._vehicle_config.rollAmplifier
		var max_roll_angle: float = afb._vehicle_config.maxRollAngle
		roll_justified = clamp(roll_justified, -max_roll_angle, max_roll_angle)
		children_roll(afb, roll_justified)

		last_yaw = current_yaw

class AFBSM_RollNormalize extends StateSingular:

	var afb = null
	var last_yaw := 0.0

	func _init():
		name = "AFBSM_RollNormalize"
		state_name = name

	func _boot():
		afb = current_machine.host

	func _compute(delta: float):
		var roll_justified: float = afb._vehicle_config.rollNormalizationSpeed * delta
		AFBSM_Roll.children_roll(afb, roll_justified)

func _init():
	._init()
	state_machine = StateMachine.new()
	state_machine.host = self
	state_machine.enforcer = self

func _ready():
	._ready()
	var planner := AFBSM_Planner.new()
	state_machine.mass_push([
		planner,
		AFBSM_Gravity.new(),
		AFBSM_Throttle.new(),
		AFBSM_Climb.new(),
		AFBSM_Steer.new(),
		AFBSM_RollNormalize.new(),
		AFBSM_Roll.new(),
	])

	planner.connect("destination_arrived", self, "des_arrived_handler")

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
	change_machine_state(true)

func change_machine_state(s := true):
	# state_machine.is_paused = s
	if s:
		state_machine.states_pool["AFBSM_Planner"].bake_next_des()

func compute(delta: float):
	state_machine._compute(delta)

func _physics_process(delta):
	compute(delta)

func _process(delta):
	compute(delta)
