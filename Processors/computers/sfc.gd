extends FlightComputer

class_name SimpleFlightComputer

# Volatile
var weapon_profile: WeaponConfiguration = null setget set_wp
var weapon_mlrs := 0.0
var weapon_sa := ForwardLookingGuidance.DEFAULT_SEEKING_ANGLE

# Persistent
var min_range_limit	 := 700.0 setget set_mrl
var mrl_squared		 := 490000.0


func _init():
	._init()
	name = "SimpleFlightComputer"
	return self

func set_wp(profile):
	weapon_profile = profile
	weapon_mlrs = weapon_profile.maxLaunchRange
	weapon_mlrs *= weapon_mlrs
	if weapon_profile.seekingAngle > 0.0:
		weapon_sa = weapon_profile.seekingAngle

func set_mrl(mrl: float):
	min_range_limit = mrl
	mrl_squared = mrl * mrl

func _boot():
	if is_instance_valid(vessel):
		vessel.overdriveThrottle = 1.0
	if is_instance_valid(controller):
		set_wp(controller.weapons["PRIMARY"])

func _compute(delta):
	if terminated or not all_check:
		return
	var fwd_vec: Vector3 = -vessel.global_transform.basis.z
	var v_pos: Vector3  = vessel.global_transform.origin
	var ev_pos: Vector3 = target.global_transform.origin
	var ds_to_target := v_pos.distance_squared_to(ev_pos)
	var angle_to_target := fwd_vec.angle_to(v_pos.direction_to(ev_pos))
	if ds_to_target < mrl_squared:
		evade_mode(delta)
	else:
		chase_mode(delta)
	if  (ds_to_target < weapon_mlrs) and \
		( angle_to_target < weapon_sa):
			fire_mode(delta)

func idle_mode(_delta):
	pass

func chase_mode(_delta):
	pass

func evade_mode(_delta):
	pass

func fire_mode(_delta):
	pass

func _target_change_handler(new_target):
	._target_change_handler(new_target)

func _vessel_change_handler(new_vessel):
	._vessel_change_handler(new_vessel)
	new_vessel.overdriveThrottle = 1.0
