extends Spatial

class_name WarheadController

export(NodePath) var explosion: NodePath = ""
export(NodePath) var aoe_collider: NodePath = ""
export(NodePath) var warhead_collider: NodePath = ""
export(float, 0.0, 10000.0) var base_damage := 10.0
export(float, 0.0, 1.0) var impact_speed_reduction := 0.3
export(float, 0.0, 100.0) var delay_time := 0.0
export var effector_1: Resource = null
export var effector_2: Resource = null
export var effector_3: Resource = null

var safety := true

onready var explosion_ref: Spatial = get_node_or_null(explosion)
onready var aoec_ref: Area = get_node_or_null(aoe_collider)
onready var wc_ref: CollisionShape = get_node_or_null(warhead_collider)
onready var tree := get_tree()

var damage_mod: DamageModifiersConfiguration = null
var last_speed := 0.0
var last_position := Vector3.ZERO
var last_fwd_vec := Vector3.ZERO

func on_peripherals_pool_entered(_ppool):
	visible = false
	if safety:
		return
	target_removal()

func target_removal():
	if delay_time > 0.0:
		yield(get_tree().create_timer(delay_time, false), "timeout")
	translation = last_position + \
		(last_fwd_vec * last_speed * impact_speed_reduction)
	look_at(translation + last_fwd_vec, Vector3.UP)
	# distribute_damage()
	if explosion_ref.has_method("make_kaboom"):
		explosion_ref.make_kaboom()

func get_effectors() -> Array:
	var re := []
	if effector_1 != null:
		re.append(effector_1)
	if effector_2 != null:
		re.append(effector_2)
	if effector_3 != null:
		re.append(effector_3)
	return re

func distribute_damage():
	var effector_list := get_effectors()
	var bodies := aoec_ref.get_overlapping_bodies()
	for b in bodies:
		if b is Combatant:
			var request := DamageRequest.new(b, base_damage, damage_mod, \
				effector_list)
			CombatServer.CombatMiddleman.damage(request)
			
