extends HomingGuidance

class_name ForwardLookingGuidance

const DEFAULT_SEEKING_ANGLE = deg2rad(30.0)

var heat_tracking = false
var heat_threshold := 10.0
var seeking_angle := DEFAULT_SEEKING_ANGLE

func _guide(delta: float):
	if not is_instance_valid(target):
		dumb_control()
		self_destruct_handler(delta)
		return
	var fwd_vec: Vector3 = -vtol.global_transform.basis.z
	var target_vec: Vector3 = vtol.global_transform.origin\
		.direction_to(target.global_transform.origin)
	var distance_squared := vtol.global_transform.origin\
		.distance_squared_to(target.global_transform.origin)
	var angle := fwd_vec.angle_to(target_vec)
	var pc_check := false
	var target_valid := false
	if proximity_mode == WeaponConfiguration.PROXIMITY_MODE.SPATIAL:
		pc_check = proximity_check(distance_squared)
		if pc_check:
			return
	if angle <= seeking_angle\
			and distance_squared <= active_range_squared:
		if heat_tracking and target is Combatant:
			if target._heat_signature > heat_threshold:
				vtol.set_tracking_target(target)
				manual_control = false
		elif vtol.trackingTarget != target:
			vtol.set_tracking_target(target)
			manual_control = false
		if proximity_mode == WeaponConfiguration.PROXIMITY_MODE.FORWARD:
			pc_check = proximity_check(distance_squared)
			if pc_check:
				return
		target_valid = true
	elif proximity_mode == WeaponConfiguration.PROXIMITY_MODE.DELAYED:
		pc_check = proximity_check(distance_squared)
		if pc_check:
			return
	if not target_valid:
		dumb_control() 
	self_destruct_handler(delta)
