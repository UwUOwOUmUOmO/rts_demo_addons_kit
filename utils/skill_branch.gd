extends Serializable

class_name SkillBranch

# Volatile
var deps_lock				:= Mutex.new()
var branches_lock			:= Mutex.new()

# Persistent
var skill_uid				:= 0
var skill_name				:= ""
var skill_description		:= ""
var activated				:= false
var activation_condition	:= {}
var skill_dependencies		:= []
var skill_attributes		:= {}
var skill_branches			:= []

func _init(serialized := {}):
	name = "SkillBranch"
	remove_properties(["deps_lock", "branches_lock"])
	if serialized != {}:
		deserialize(serialized)

func add_dependency(id: int):
	deps_lock.lock()
	skill_dependencies.append(id)
	deps_lock.unlock()

func add_branch(id: int):
	branches_lock.lock()
	skill_branches.append(id)
	branches_lock.unlock()
