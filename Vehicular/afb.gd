extends AirCombatant

class_name AdvancedFighterBrain

onready var  fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta


var accbs: AirComCBS = null
var afb_computer: AFB_Logic = null

class AFB_Logic extends Reference:

	var host: AdvancedFighterBrain = null

	# Static
	var deadzone_squared := 0.0
	var orbit_error_squared := 0.0
	var vehicle_config: AircraftConfiguration = null

	# Persistent
	var current_roll := 0.0
	var previous_yaw := 0.0
	var target_roll := 0.0

	# Volatile
	var current_yaw := 0.0
	var allowed_turn := 0.05
	var speed_loss := 0.0
	var raw_speed_loss := 0.0
	var sdz_squared := 0.0
	var slowing_range_squared := 0.0

	static func turn(vessel: Spatial, to: Vector3, turningSpeed: float):
		var global_pos = vessel.global_transform.origin
		var target_pos = to
		var rotation_speed = turningSpeed
		var wtransform = vessel.global_transform.\
			looking_at(Vector3(target_pos.x,global_pos.y,target_pos.z),Vector3.UP)
		var wrotation = Quat(vessel.global_transform.basis).slerp(Quat(wtransform.basis),\
			rotation_speed)

		vessel.global_transform = Transform(Basis(wrotation), vessel.global_transform.origin)

	func _init(target: AdvancedFighterBrain):
		host = target
		static_value_set()

	func static_value_set():
		deadzone_squared = vehicle_config.deadzone
		orbit_error_squared = vehicle_config.orbitError
		vehicle_config = vehicle_config
		previous_yaw = host.global_transform.basis.get_euler().y

	func volatile_reset():
		pass

	func _compute(delta: float):
		var new_distance := Vector3.ZERO
		if (host.throttle == 0.0 and host.currentSpeed == 0.0) \
			or not host.isMoving:
				return
		else:
			new_distance += conventional_flight()

		# Finalize
		previous_yaw = current_yaw

	func conventional_flight():
		# Preparations
		var delta_distance := Vector3.ZERO
		var allowed_speed: float = vehicle_config.maxSpeed \
			* host.throttle
		current_yaw = host.global_transform.basis.get_euler().y
		host.distance_squared = host.global_transform.origin.distance_to(\
			host.current_destination)
		var accel: float = vehicle_config.deccelaration
		var slowingTime: float = vehicle_config.slowingTime
		host.slowingRange = (host.currentSpeed * slowingTime) + (0.5 * accel * slowingTime)
		host.slowingRange_squared = host.slowingRange * host.slowingRange
		host.speedPercentage = Utilities.TrialTools.try_divide(\
			host.currentSpeed, allowed_speed)
		compute_turn_rate()
		set_throttle()
		turn(host, host.current_destination, allowed_turn)
		# Enforcement
		set_roll()
		calculate_speed(allowed_speed)

	func compute_turn_rate():
		var minTurnRate = vehicle_config.turnRate
		var maxTurnrate = vehicle_config.maxTurnRate
		allowed_turn = lerp(maxTurnrate, minTurnRate, clamp(host.speedPercentage, 0.0, 1.0))
		#---------------------------------------------------------------------
		var fwd_vec := -host.global_transform.basis.z
		var target_vec := host.global_transform.origin.direction_to(host.current_destination)
		var angle := abs(fwd_vec.angle_to(target_vec))
		var percentage: float = angle / Combatant.FORE
		var aero: float = vehicle_config.aerodynamic
		var loss_rate := 1.0 - aero
		var real_loss: float = loss_rate * percentage * \
			allowed_turn * vehicle_config.speedLossMod
		speed_loss = real_loss

	func set_throttle():
		if host.overdriveThrottle > 0.0:
			host.throttle = host.overdriveThrottle
			if host.distance_squared <= deadzone_squared * 2.0:
				host.chart_course()
			return
		if host.distance_squared <= sdz_squared:
			if host.chart_course():
				return
		if host.distance_squared <= deadzone_squared:
			host.throttle = 0.0
			host.set_moving(false)
			# if host.currentSpeed < vehicle_config.speedSnapping \
			# 	and host.throttle <= vehicle_config.minThrottle:
			# 		return
			if host.currentSpeed < vehicle_config.speedSnapping\
				and host.throttle <= vehicle_config.minThrottle:
					return
			elif host.distance_squared <= orbit_error_squared:
				host.global_translate(
					host.current_destination - host.global_transform.origin)
		elif slowing_range_squared >= host.distance_squared:
			host.throttle = 0.0
		elif host.throttle != 1.0:
			host.throttle = 1.0

	func calculate_speed(allowed_speed: float):
		var speedMod := 0.0
		var clampMin := 0.0
		if host.currentSpeed < allowed_speed:
			speedMod = vehicle_config.acceleration
			clampMin = 0.0
		elif host.currentSpeed > allowed_speed:
			speedMod = vehicle_config.deccelaration
			clampMin = allowed_speed
		raw_speed_loss = abs(vehicle_config.deccelaration * speed_loss)
		host.currentSpeed = clamp(clamp(host.currentSpeed + speedMod, \
			clampMin, vehicle_config.maxSpeed) - raw_speed_loss, 0.0, vehicle_config.maxSpeed)

	func set_roll():
		var roll := current_yaw - previous_yaw
		target_roll = clamp(roll * vehicle_config.rollAmplifier, \
			-vehicle_config.maxRollAngle, vehicle_config.maxRollAngle)

	func deferred_roll(weight := 0.05):
		current_roll = lerp(current_roll, target_roll, weight)
		for child in host.get_children():
			if child is Spatial:
				child.rotation.z = current_roll

# Public functions
func _init():
	._init()
	afb_computer = AFB_Logic.new(self)

func _ready():
	._ready()
	accbs = AirComCBS.new(self)
	add_child(accbs)
	accbs.owner = self
	process_switch()

func set_course(des: Vector3):
	current_destination = des

func set_moving(m: bool):
	isMoving = m
	afb_computer.volatile_reset()

# Main logics
func _process(delta):
	afb_computer._compute(delta)

func _physics_process(delta):
	afb_computer._compute(delta)

func chart_course() -> bool:
	return false
