extends Spatial

class_name CombatantController


enum TARGET_TYPE 	{AIRBORNE, GROUND, ONPHASE, UNKNOWN}
enum TARGET_STANCE 	{STATIC, MOVABLE, UNKNOWN}

var use_physics_process: bool		= true
var assigned_combatant: Combatant	= null
var target: Combatant				= null
var computer: CombatComputer		= null
var sensor: CombatSensor			= null

var tracking := false
