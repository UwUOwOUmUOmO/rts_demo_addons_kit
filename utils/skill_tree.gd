extends Serializable

class_name SkillTree

const ST_UID_START_NUM := 10000

# Volatile
var table_lock		:= Mutex.new()

# Persistent
var tree_name		:= ""
var current_uid		:= ST_UID_START_NUM
var lookup_table	:= {}

func _init(serialized := {}):
	name = "SkillTree"
	remove_properties(["table_lock"])
	if serialized != {}:
		deserialize(serialized)

func add_branch(branch):
	table_lock.lock()
	lookup_table[current_uid] = branch
	current_uid += 1
	table_lock.unlock()

func fetch_branch(id: int):
	return lookup_table[id]

func duplicate_table(deep := false):
	if not deep:
		return lookup_table
	var table_dup := {}
	for id in lookup_table:
		var branch = lookup_table[id]
		table_dup[id] = branch.config_duplicate()
	return table_dup
