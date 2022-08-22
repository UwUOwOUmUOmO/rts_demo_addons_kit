extends Serializable

class_name TeamConfiguration

# Exports
export var team_name			:= ""

# Persistent
var team_catalog				:= {}
var last_id						:= 0

# Volatile
var tc_mutex					:= Mutex.new()

func _init():
	name = "TeamConfiguration"
	remove_property("tc_mutex")

func add_squadrons(squadron_list: Array):
	tc_mutex.lock()
	for squadron in squadron_list:
		if not squadron is SquadronConfiguration:
			continue
		team_catalog[last_id] = squadron
		last_id += 1
	tc_mutex.unlock()

func add_squadron(squadron: SquadronConfiguration):
	add_squadrons([squadron])

