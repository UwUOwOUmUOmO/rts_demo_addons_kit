extends Configuration

class_name SquadronConfiguration

# Exports
export var squadron_name								:= ""
export var squadron_formation_packed: PackedScene		 = null

# Persistent
var last_callsign										:= "P0"
var last_id												:= 0
var squadron_catalog									:= {}

# Volatile
var sc_mutex											:= Mutex.new()

func _init():
	name = "SquadronConfiguration"
	remove_property("sc_mutex")

func add_fighters(fighter_list: Array):
	sc_mutex.lock()
	for fighter in fighter_list:
		if not fighter is AircraftConfiguration:
			continue
		squadron_catalog[last_callsign] = fighter
		last_id += 1
		last_callsign = "P" + str(last_id)
	sc_mutex.unlock()

func add_fighter(fighter: AircraftConfiguration):
	add_fighters([fighter])
