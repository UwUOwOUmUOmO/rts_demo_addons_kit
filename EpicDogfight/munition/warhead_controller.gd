extends Spatial

class_name WarheadController

export(NodePath) var explosion: NodePath = ""
export(NodePath) var aoe_collider: NodePath = ""
export(float, 0.0, 1.0) var impact_speed_reduction := 0.3
export(float, 0.0, 100.0) var delay_time := 0.0

var safety := true

onready var explosion_ref: Spatial = get_node_or_null(explosion)
onready var aoec_ref: Area = get_node_or_null(aoe_collider)
onready var tree := get_tree()

var base_dmg := 0.0
var damage_mod: DamageModifiersConfiguration = null
var last_speed := 0.0
var last_position := Vector3.ZERO
var last_fwd_vec := Vector3.ZERO

func on_peripherals_pool_entered(_ppool):
	if safety:
		return
	target_removal()

func target_removal():
	if delay_time > 0.0:
		yield(get_tree().create_timer(delay_time, false), "timeout")
	translation = last_position + \
		(last_fwd_vec * last_speed * impact_speed_reduction)
	look_at(translation + last_fwd_vec, Vector3.UP)
	distribute_damage()
	if explosion_ref.has_method("make_kaboom"):
		explosion_ref.make_kaboom()

func distribute_damage():
	var bodies := aoec_ref.get_overlapping_bodies()
	for b in bodies:
		if b is Combatant:
			b._damage(10.0)
