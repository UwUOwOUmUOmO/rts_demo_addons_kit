extends Spatial

class_name CombatantController


enum TARGET_TYPE 	{AIRBORNE, GROUND, ONPHASE, UNKNOWN}
enum TARGET_STANCE 	{STATIC, MOVABLE, UNKNOWN}

var _use_physics_process := true
var _assigned_combatant: Combatant		 		= null
var _target: Combatant							= null
var _tracking := false

var _is_stealthy := false
var _weapons := {
	"main":		null,
	"second":	null
}
var _target_profile = {
	"type":		TARGET_TYPE.UNKNOWN,
	"stance":	TARGET_STANCE.UNKNOWN,
}
var _config := {}
