extends Configuration

class_name HullProfile

const ALIVE_THRESHOLD := 0.0

signal __out_of_hp()

# ARMOR_TYPE is blenable
# Example: armor: int = ARMOR_TYPE.PLATED + ARMOR_TYPE.COMPOSITE
enum ARMOR_TYPE {
	NA = 0,
	SPACED = 1,
	PLATED = 2,
	COMPOSITE = 4,
	STRUCTURE = 8,
	FORT = 16,
}

# Persistent
var current_hp := 100.0
var max_hp := 100.0
var min_hp := 0.0
var armor_type: int = ARMOR_TYPE.NA
# Resistant to WARHEAD_TYPE
var resistant: PoolRealArray = [
	1.0, 1.0, 1.0,
	1.0, 1.0, 1.0
]
var effector_pool := []

# Volatile
var hull_mutex := Mutex.new()
var no_hp_emitted := false

func _init():
	name = "HullProfile"
	remove_properties(["hull_mutex", "no_hp_emitted"])

func damage(processed_damage: float):
	hull_mutex.lock()
	current_hp = clamp(current_hp - processed_damage, min_hp, max_hp)
	if current_hp <= ALIVE_THRESHOLD and not no_hp_emitted:
		emit_signal("__out_of_hp")
		no_hp_emitted = true
	hull_mutex.unlock()
