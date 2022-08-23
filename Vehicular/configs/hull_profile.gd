extends Serializable

class_name HullProfile

const ALIVE_THRESHOLD := 0.0
const OVER_TIME_INTERVAL := 1.0

signal __out_of_hp()
signal __hp_updated(hull, curr_amout, change)
signal __min_hp_reached(hull)
signal __max_hp_reached(hull)

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
var current_hp := 100.0 setget set_hp
var max_hp := 100.0 setget set_max_hp
var min_hp := 0.0 setget set_min_hp
var armor_type: int = ARMOR_TYPE.NA
# Resistant to WARHEAD_TYPE
var resistant: PoolRealArray = [
	1.0, 1.0, 1.0,
	1.0, 1.0, 1.0
]
var effector_pool := []
var no_hp_emitted := false

# Volatile
var hull_mutex : = Mutex.new()
var limit_mutex := Mutex.new()

func _init():
	name = "HullProfile"
	remove_properties(["hull_mutex", "limit_mutex"])

func set_hp(amount: float):
	current_hp = clamp(amount, min_hp, max_hp)

func set_min_hp(val: float):
	limit_mutex.lock()
	min_hp = val
	limit_mutex.unlock()

func set_max_hp(val: float):
	limit_mutex.lock()
	max_hp = val
	limit_mutex.unlock()

func damage(processed_damage: float):
	if not no_hp_emitted:
		hull_mutex.lock()
		var old_hp := current_hp
		processed_damage = abs(processed_damage)
		set_hp(current_hp - processed_damage)
		emit_signal("__hp_updated", self, current_hp, -processed_damage)
		if old_hp == current_hp:
			emit_signal("__min_hp_reached", self)
		if current_hp <= ALIVE_THRESHOLD:
			emit_signal("__out_of_hp")
			no_hp_emitted = true
		hull_mutex.unlock()

func heal(amount: float):
	if not no_hp_emitted:
		var old_amount := current_hp
		hull_mutex.lock()
		amount = abs(amount)
		set_hp(current_hp + amount)
		if old_amount != current_hp:
			emit_signal("__hp_updated", self, current_hp, amount)
		if old_amount == current_hp:
			emit_signal("__max_hp_reached", self)
		hull_mutex.unlock()

# WARNING: Do not use OT functions with negative duration
# it is currently impossible to shut down these OT unless no_hp_emitted is true
# Use for debugging purpose only
func damage_over_time(amount: float, duration := -1.0):
	if duration <= 0.1:
		while not no_hp_emitted:
			yield(Out.timer(OVER_TIME_INTERVAL), "timeout")
			damage(amount)
	else:
		var timer := 0.0
		var amount_per_turn := amount / OVER_TIME_INTERVAL
		while timer < duration:
			yield(Out.timer(OVER_TIME_INTERVAL), "timeout")
			timer += OVER_TIME_INTERVAL
			damage(amount_per_turn)

func heal_over_time(amount: float, duration := -1.0):
	if duration <= 0.1:
		while not no_hp_emitted:
			yield(Out.timer(OVER_TIME_INTERVAL), "timeout")
			heal(amount)
	else:
		var timer := 0.0
		var amount_per_turn := amount / OVER_TIME_INTERVAL
		while timer < duration:
			yield(Out.timer(OVER_TIME_INTERVAL), "timeout")
			timer += OVER_TIME_INTERVAL
			heal(amount_per_turn)
