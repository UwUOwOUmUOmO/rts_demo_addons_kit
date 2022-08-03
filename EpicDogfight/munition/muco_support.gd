extends Node

var exp_packed: PackedScene = null
var position := Vector3.ZERO
var fwd_vec := Vector3.ZERO
var is_primed := false
var delay := 0.0

func _ready():
	print("Woop Woop")
	if is_primed:
		make_kaboom()

func make_kaboom():
	if exp_packed == null:
		return
	if delay > 0.0:
		yield(get_tree().create_timer(delay), "timeout")
	var new_kaboom = exp_packed.new()
	LevelManager.template.add_peripheral(new_kaboom)
	while not is_instance_valid(new_kaboom.get_parent()):
		yield(get_tree(), "idle_frame")
	new_kaboom.global_translate(position)
	new_kaboom.look_at(position + fwd_vec, Vector3.UP)
	if new_kaboom.has_method("play"):
		new_kaboom.play()
