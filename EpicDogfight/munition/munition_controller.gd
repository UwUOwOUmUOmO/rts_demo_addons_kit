extends Spatial

class_name MunitionController

const MUCOSUP := preload("res://addons/EpicDogfight/munition/muco_support.gd")

export(NodePath) var warhead := "" setget set_whh
export(NodePath) var aoe := "" setget set_aoeh
export(NodePath) var particles_holder := "" setget set_phh
export(PackedScene) var explosion: PackedScene = null setget set_exp
export(float, 0.0, 100.0) var delay_time := 0.0 setget set_delay
export(float, 0.0, 1.0) var impact_speed_reduction := 0.3 setget set_reduction

var warhead_ref: Area = null setget set_warhead
var aoe_ref: Area = null setget set_aoe
var ph_ref: Spatial = null setget set_ph

var last_pos := Vector3.ZERO
var last_speed := 0.0
var particles_list := []
var guidance: WeaponGuidance = null
var _ref: InRef = null

# Exports set/get
func set_whh(wh: String):
	warhead = wh
	var path := wh
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is Area:
		Out.print_error("Referenced node must be of type: Area", get_stack())
	set_warhead(c)

func set_aoeh(zone: String):
	aoe = zone
	var path := zone
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is Area:
		Out.print_error("Referenced node must be of type: Area", get_stack())
	set_aoe(c)

func set_phh(ph: String):
	particles_holder = ph
	var path := ph
	var c := get_node_or_null(path)
	if c == null:
		return
	if not c is Spatial:
		Out.print_error("Referenced node must be of type: Spatial", get_stack())
	set_ph(c)

func set_exp(e: PackedScene):
	explosion = e

func set_delay(t: float):
	delay_time = t

func set_reduction(re: float):
	impact_speed_reduction = re

# Main set/get
func set_warhead(wh: Area):
	var old_warhead := warhead
	warhead_ref = wh

func set_aoe(zone: Area):
	var old_aoe := aoe
	aoe_ref = zone

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

func __is_projectile():
	return true

func arm_launched(g: WeaponGuidance):
	guidance = g
	_start()

func arm_arrived(g: WeaponGuidance):
	last_pos = global_transform.origin
	if g._weapon_base_config.weaponGuidance == WeaponConfiguration.GUIDANCE.NA:
		last_speed = g._weapon_base_config.travelSpeed
	else:
		last_speed = g.vtol.currentSpeed
	_finalize()

func _start():
	pass

func _finalize():
	var ppool := LevelManager.template
	for p in particles_list:
		ph_ref.remove_child(p)
		ppool.add_peripheral(p, p.lifetime)
	var fwd_vec: Vector3 = -global_transform.basis.z
	var supporter = MUCOSUP.instance()
	supporter.exp_packed = explosion
	supporter.position = last_pos + \
		(delay_time * last_speed * impact_speed_reduction * fwd_vec)
	supporter.fwd_vec = fwd_vec
	supporter.is_primed = true
	supporter.delay = delay_time
	ppool.add_peripheral(supporter)
