extends Reference

class_name PackageParasite

const assets_instance := preload("res://addons/GameFramework/com/assets_instance.tscn")

func inject(package: Array, old_self: Node, current_tree: SceneTree):
	reference()
	while is_instance_valid(old_self) or current_tree.get_current_scene() != null:
		yield(current_tree, "idle_frame")
	var instance := assets_instance.instance()
	instance.assets = package
	current_tree.current_scene.add_child(instance)
	unreference()
