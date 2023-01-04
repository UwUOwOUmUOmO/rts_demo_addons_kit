tool
extends EditorPlugin

var _bottom_panel = null


func _enter_tree():
	_bottom_panel = preload('res://addons/gut/gui/GutBottomPanel.tscn').instance()
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
	add_custom_type("Gut", "Control", preload("plugin_control.gd"), preload("icon.png"))

	var button = add_control_to_bottom_panel(_bottom_panel, 'GUT')
	button.shortcut_in_tooltip = true

	yield(get_tree().create_timer(3), 'timeout')
	_bottom_panel.set_interface(get_editor_interface())
	_bottom_panel.set_plugin(self)
	_bottom_panel.set_panel_button(button)
	_bottom_panel.load_shortcuts()

static func free_stuff_nav(stuff, rec: int = 0):
	if stuff == null:
		return
	if rec >= 512:
		return
	rec += 1
	if stuff is Array:
		free_stuff_array(stuff, rec)
	elif stuff is Dictionary:
		free_stuff_dict(stuff, rec)
	elif stuff is Object:
		free_stuff(stuff, rec)

static func free_stuff_array(arr: Array, rec: int = 0):
	if rec >= 512:
		return
	rec += 1
	for elem in arr:
		free_stuff_nav(elem, rec)
	arr.clear()

static func free_stuff_dict(dict: Dictionary, rec: int = 0):
	if rec >= 512:
		return
	rec += 1
	for key in dict:
		var value = dict[key]
		free_stuff_nav(key, rec)
		free_stuff_nav(value, rec)
	dict.clear()

static func free_stuff(at: Object, rec: int = 0):
	if rec >= 512:
		return
	rec += 1
	if at == null:
		return
	for p_list in at.get_property_list():
		# Not script instance
		if not (p_list['usage'] & 8192):
			continue
		# No class
		# if p_list['class_name'] == '':
		# 	continue
		var ins = at.get(p_list['name'])
		# Not an object
		if ins == null:
			continue
		# if not (ins is Object) or not (ins is Array) or not (ins is Dictionary):
		# 	continue
		print("Inspecting: " + p_list['name'])

		# Recursion
		# if is a Reference, unref it
		if p_list['name'] is Object:
			at.set(p_list['name'], null)
		free_stuff_nav(ins, rec)
	if at is Reference:
		return
	print("Freing " + str(at))
	if at is Node:
		at.queue_free()
	else:
		at.free()

func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove it from the engine when deactivated
	remove_custom_type("Gut")
	remove_control_from_bottom_panel(_bottom_panel)
	# _bottom_panel.free()
	free_stuff(_bottom_panel)
