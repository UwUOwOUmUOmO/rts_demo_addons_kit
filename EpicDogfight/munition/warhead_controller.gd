extends Spatial

class_name WarheadController

signal __warhead_finalized()

const EFFECT_SIGNALS := {
	"finished": "_finalize"
}

export(NodePath) var explosion: NodePath = ""
export(NodePath) var aoe_collider: NodePath = ""
export(NodePath) var warhead_collider: NodePath = ""
export(int, "Area", "PhysicsDirectSpaceState") var collision_mode := 0
export(bool) var inert := false
export(float, 0.01, 1.0, 0.01) var monitor_period := 0.05
export (float, 0.001, 100.0, 0.001) var collision_margin := 1.0
export(float, 0.0, 10000.0) var base_damage := 10.0
export(float, 0.0, 1.0) var impact_speed_reduction := 0.3
export(float, 0.0, 100.0) var delay_time := 0.0
export(float, 0.0, 100.0) var explosion_lifetime := 0.0
export var damage_modifier: Resource = null
export var effect_1: Resource = null
export var effect_2: Resource = null
export var effect_3: Resource = null

onready var munition_ref = get_parent_spatial()
onready var allow_damage: bool = SingletonManager.static_services["UtilsSettings"].allow_damage
onready var explosion_ref: Spatial = get_node_or_null(explosion)
onready var aoec_ref: Area = get_node_or_null(aoe_collider)
onready var wc_ref: Area = get_node_or_null(warhead_collider)
onready var tree := get_tree()

var mask := 0
var monitor_time := 0.0
var last_speed := 0.0
var checked: PoolIntArray = []

func projectile_crash(speed: float):
	translation -= Vector3(0.0, 0.0, speed * impact_speed_reduction)

func _ready():
	set_process(false)
	Utilities.SignalTools.connect_from(explosion_ref, self, EFFECT_SIGNALS)
	mask = wc_ref.collision_mask
	if collision_mode == 0:
		wc_ref.set_deferred("monitoring", true)
		set_physics_process(false)
	else:
		wc_ref.set_deferred("monitoring", false)
		set_physics_process(true)
	wc_ref.set_deferred("monitorable", false)

onready var exclusion := [wc_ref, aoec_ref]

func _physics_process(_delta):
#	if collision_mode != 1: return
	var space_state := get_world().direct_space_state
	var from := global_transform.origin
	var fwd_vec := -global_transform.basis.z
	var to := from + (fwd_vec * collision_margin)
	var result := space_state.intersect_ray(from, to, exclusion, mask, true, true)
	if not result.empty():
		munition_ref.premature_detonation_handler(result["collider"])
		return

func _process(delta):
	distribute_damage()
	monitor_time += delta
	if monitor_time > monitor_period: set_process(false)

func play():
	if delay_time > 0.0:
		yield(Out.timer(delay_time), "timeout")
	if explosion_ref:
		explosion_ref.animation_lifetime = explosion_lifetime
		explosion_ref.make_kaboom()
	if aoec_ref:
		aoec_ref.set_deferred("monitoring", true)
	if not inert and allow_damage:
#		distribute_damage()
		set_process(true)
#	_finalize()

func get_effects() -> Array:
	var re := []
	if effect_1 != null:
		re.append(effect_1)
	if effect_2 != null:
		re.append(effect_2)
	if effect_3 != null:
		re.append(effect_3)
	return re

func distribute_damage():
	var effect_list := get_effects()
	if not aoec_ref: return
	var bodies: Array = aoec_ref.get_overlapping_bodies()
	for b in bodies:
		var com = b
		var id: int = com.get_instance_id()
		if id in checked:
			continue
		if com is Combatant:
#			Hub.print_custom(str(self), "Hit on: [0]".format([com]), [])
			if com._controller is WeaponGuidance:
				com._controller._finalize()
				continue
			var request := DamageRequest.new(com, base_damage, damage_modifier, \
				effect_list)
			checked.push_back(id)
			CombatServerGDS.CombatMiddleman.damage(request)

func _finalize():
#	if explosion_lifetime > 0.0:
#		yield(Out.timer(explosion_lifetime), "timeout")
	emit_signal("__warhead_finalized")
	queue_free()
