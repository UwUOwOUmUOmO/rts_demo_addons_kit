extends Spatial

class_name WeaponGuidance

const PROJECTILE_DEFAULT_SIGNALS := {
	"__armament_fired":			"arm_launched",
	"__armament_detonated":		"arm_arrived",
}

signal __armament_fired(guidance)
signal __armmament_armed(guidance)
signal __armament_detonated(guidance)

onready var processors_swarm = SingletonManager.fetch("ProcessorsSwarm")
onready var  fixed_delta: float = SingletonManager.fetch("UtilsSettings")\
			.fixed_delta

var _weapon_base_config: WeaponConfiguration = null

var _barrel := Vector3.ZERO
var _direction := Vector3.ZERO
var _use_physics_process: bool = SingletonManager.fetch("UtilsSettings") \
	.use_physics_process
var _projectile: Spatial = null
var _computer: FlightComputer = null
var _instrument: AirInstrument = null
var _cluster: ProcessorsCluster = null
var _damage_zone: Area = null
var _green_light := false
var _arm_time := 0.3
var _armed := false setget set_armed
var _autofree_projectile := true

func set_armed(a: bool):
	_armed = a
	if a:
		emit_signal("__armmament_armed")

func _process(delta):
	if not _use_physics_process and _green_light:
		_guide(delta)

func _physics_process(delta):
	if _use_physics_process and _green_light:
		_guide(fixed_delta)

func _guide(delta: float):
	pass

func _start(move := true):
	if move:
		global_translate(_barrel - global_transform.origin)
	look_at(_direction, Vector3.UP)
	_projectile = _weapon_base_config.projectile.instance()
	LevelManager.template.add_peripheral(_projectile)
	yield(get_tree(), "idle_frame")
	# add_child(_projectile)
	# _projectile.owner = self
	_projectile.translation = Vector3.ZERO
	_projectile.look_at(global_transform.origin + _direction, Vector3.UP)
	_signals_init()
	_initialize()
	set_armed(true)
	_green_light = true
	_boot_subsys()

func _signals_init():
	Toolkits.SignalTools.connect_from(self, _projectile, \
		PROJECTILE_DEFAULT_SIGNALS, true)

func _boot_subsys():
	_cluster = processors_swarm.add_cluster(name + "_proc_cluster")
	_cluster.host = self
	var required_cluster := false
	if is_instance_valid(_computer) and not _computer.enforcer_assigned:
		required_cluster = true
		_cluster.add_nopr(_computer)
	if is_instance_valid(_instrument) and not _instrument.enforcer_assigned:
		required_cluster = true
		_cluster.add_nopr(_instrument)
	if not required_cluster:
		_cluster.queue_free()
	else:
		_cluster.commission()
		if not _computer.coprocess:
			set_physics_process(false)
			set_process(false)

func _initialize():
	emit_signal("__armament_fired", self)

func _finalize():
	_green_light = false
	emit_signal("__armament_detonated", self)
	_clean()

func _clean():
	if _autofree_projectile:
		queue_free()

func _exit_tree():
	Toolkits.TrialTools.try_call(_cluster,   "decommission")
	Toolkits.TrialTools.try_set(_computer,   "terminated", true)
	Toolkits.TrialTools.try_set(_instrument, "terminated", true)
