extends Configuration

class_name SkillTree

enum SKILL_FETCH_MODE { FETCH, FLICK, COLLECT_ATTR }

# Volatile
var skill_origin = null

# Persistent
var skill_uid				:= 0
var skill_name				:= ""
var skill_description		:= ""
var activated				:= false
var activation_condition	:= {}
var skill_attributes		:= {}
var skill_branches			:= {}

func _init():
	
	no_deep_scan.append("skill_attributes")
	remove_property("skill_origin")
	name = "SkillTree"
	return self

func fetch_skill(s_name: String, branches: Dictionary):
	for key in branches:
		var value = branches[key]
		if value.skill_name == s_name:
			return value
	return null

func fetch_from_id(uid: int):
	if skill_uid == uid:
		return self
	for key in skill_branches:
		var value = skill_branches[key]
		var fetched = value.fetch_from_id(uid)
		if fetched != null:
			return fetched
	return null
		
func fetch(skill_path: String):
	return manipulate(skill_path)

func flick(skill_path: String, sig := true):
	return manipulate(skill_path, SKILL_FETCH_MODE.FLICK, sig)

func collect_attributes(skill_path: String):
	return manipulate(skill_path, SKILL_FETCH_MODE.COLLECT_ATTR)

func manipulate(skill_path: String, mode: int = SKILL_FETCH_MODE.FETCH, sig := false):
	var path_utils = SingletonManager.fetch("PathUtils")
	var sliced_path := Array(path_utils.slice_path(skill_path))
	var re = null
	var attr := [skill_attributes]
	var current_branch := skill_branches
	if mode == SKILL_FETCH_MODE.FLICK:
		activated = sig
	while true:
		var curr_skill_name: String = sliced_path.pop_front()
		if curr_skill_name == null:
			break
		re = fetch_skill(curr_skill_name, current_branch)
		if re == null:
			Out.print_error("Failed to fetch skill at path: "\
				+ skill_path, get_stack())
			return null
		if mode == SKILL_FETCH_MODE.FLICK:
			re.activated = sig
		current_branch = re.skill_branches
		attr.append(re.skill_attributes)
		
	if mode == SKILL_FETCH_MODE.FETCH:
		return re
	elif mode == SKILL_FETCH_MODE.COLLECT_ATTR:
		return attr
	else:
		return null