extends Spatial

class_name MunitionController

export(NodePath) var warhead := "" setget set_whh
export(NodePath) var particles_holder := "" setget set_phh
export(Resource)var damage_modifier = null

var warhead_ref: WarheadController = null setget set_warhead
var ph_ref: Spatial = null setget set_ph

var is_ready := false
var last_pos := Vector3.ZERO
var last_fwd_vec := Vector3.ZERO
var last_speed := 0.0
var particles_list := []
var guidance: WeaponGuidance = null
var _ref: InRef = null

# Exports set/get
func set_whh(wh: String):
	warhead = wh
	if not is_ready:
		return
	var path := wh
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is WarheadController:
		Out.print_error("Referenced node must be of type: Area", get_stack())
	set_warhead(c)

func set_phh(ph: String):
	particles_holder = ph
	if not is_ready:
		return
	var path := ph
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is Spatial:
		Out.print_error("Referenced node must be of type: Spatial", get_stack())
	set_ph(c)

# Main set/get
func set_warhead(wh: WarheadController):
	var old_warhead := warhead_ref
	if old_warhead != null:
		var collider = old_warhead.wc_ref
		if collider != null:
			collider.disconnect("body_entered", self, "premature_detonation_handler")
	warhead_ref = wh
	if warhead_ref.wc_ref != null:
		warhead_ref.wc_ref.connect("body_entered", self, "premature_detonation_handler")

func set_ph(ph: Spatial):
	ph_ref = ph
	particles_list = []
	var children := ph.get_children()
	for c in children:
		if c is Particles:
			particles_list.append(c)

# Main functions
func _ready():
	_ref = InRef.new(self)
	_ref.add_to("munition_controllers")
	set_whh(warhead)
	set_phh(particles_holder)
	is_ready = true

func __is_projectile():
	return true

func arm_launched(g: WeaponGuidance):
	guidance = g
	_start()

func arm_arrived(g: WeaponGuidance):
	last_pos = global_transform.origin
	last_fwd_vec = -global_transform.basis.z
	if g._weapon_base_config.weaponGuidance == WeaponConfiguration.GUIDANCE.NA:
		last_speed = g._weapon_base_config.travelSpeed
	else:
		last_speed = g.vtol.currentSpeed
	_finalize()

func premature_detonation_handler():
	arm_arrived(guidance)

func _start():
	pass

func _finalize():
	var ppool := LevelManager.template
	for p in particles_list:
		ph_ref.remove_child(p)
		ppool.add_peripheral(p, p.lifetime)
	warhead_ref.safety = false
	warhead_ref.damage_modifier = damage_modifier
	warhead_ref.last_speed = last_speed
	warhead_ref.last_position = last_pos
	warhead_ref.last_fwd_vec = last_fwd_vec
	# -----------------------------------------
	remove_child(warhead_ref)
	ppool.add_peripheral(warhead_ref)
	queue_free()
