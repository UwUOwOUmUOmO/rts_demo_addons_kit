extends Configuration

class_name SkillTree

# Volatile
var skill_origin = null

# Persistent
var skill_name := ""
var skill_description := ""
var skill_atribute := {}
var skill_branches := {}

func _init():
	._init()
	no_deep_scan.append("skill_atribute")
	remove_property("skill_origin")
	name = "SkillTree"
	return self
