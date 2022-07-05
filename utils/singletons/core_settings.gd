extends Node

var use_physics_process := true
var physics_fps: int = ProjectSettings.get_setting("physics/common/physics_fps")
var fixed_delta := 1.0 / float(physics_fps)

static func connect_from(from: Object, to: Object, table: Dictionary) -> void:
	if not is_instance_valid(from) or not is_instance_valid(to):
		Out.print_error("Invalid connection", get_stack())
		return
	for sig in table:
		var handler: String = table[sig]
		from.connect(sig, to, handler)

static func disconnect_from(from: Object, to: Object, table := {}):
	if table.empty():
		disconnect_all(from, to)
		return
	if not is_instance_valid(from) or not is_instance_valid(to):
		Out.print_error("Invalid connection", get_stack())
		return
	for sig in table:
		var handler: String = table[sig]
		from.disconnect(sig, to, handler)

static func disconnect_all(from: Object, to: Object):
	var all_signals := from.get_signal_list()
	for sig in all_signals:
		var sig_name: String = sig["name"]
		var connection_list := from.get_signal_connection_list(sig_name)
		for connection in connection_list:
			if connection["target"] == to:
				from.disconnect(sig_name, to, connection["method"])
