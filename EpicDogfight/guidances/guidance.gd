extends Spatial

class_name WeaponGuidance

var _init_func: FuncRef = null
var _init_func_package := []
var _fin_func: FuncRef = null
var _fin_func_package := []
var _velocity := 0.0
var _barrel := Vector3.ZERO
var _direction := Vector3.ZERO
var _use_physics_process := true
var _projectile_scene: PackedScene = null
var _projectile: Spatial = null
var _green_light := false

func _process(delta):
	if not _use_physics_process and _green_light:
		_guide(delta)

func _physics_process(delta):
	if _use_physics_process and _green_light:
		_guide(delta)

func _guide(delta: float):
	pass

func _start(move := true):
	if move:
		global_translate(_barrel - global_transform.origin)
	look_at(_direction, Vector3.UP)
	_projectile = _projectile_scene.instance()
	add_child(_projectile)
	_projectile.translation = Vector3.ZERO
	_initialize()
	_green_light = true

func _initialize():
	if _init_func:
		if _init_func_package.empty():
			_init_func.call_func()
		else:
			_init_func.call_funcv(_init_func_package)

func _finalize():
	_green_light = false
	if _fin_func:
		if _fin_func_package.empty():
			_fin_func.call_func()
		else:
			_fin_func.call_funcv(_fin_func_package)

func _clean():
	var p_parent := _projectile.get_parent()
	if p_parent:
		p_parent.remove_child(_projectile)
	_projectile.free()
	queue_free()
