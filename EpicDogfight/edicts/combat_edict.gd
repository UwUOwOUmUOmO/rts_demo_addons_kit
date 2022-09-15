extends Edicts

# Abstract class do not explicitly instance this
class_name CombatEdict

enum COMBAT_EDICT_DEMOGRAPHICS {
	UNSPECIFIED			= Utilities.BitMask.BIT_0,
	TEAM_GRADE			= Utilities.BitMask.BIT_1,
	SQUAD_GRADE			= Utilities.BitMask.BIT_2,
	COMBATANT_GRADE		= Utilities.BitMask.BIT_3,
	MULTIGRADES 		= Utilities.BitMask.BITMASK_1ST_WORD \
						- Utilities.BitMask.BIT_4,
#	Bit mask:			  0000 0000 0000 0000
#						  0000 0000 0000 0111
}
enum COMBAT_EDICT_CATEGORIES {
	UNSPECIFIED			= Utilities.BitMask.BIT_0,
	ENGAGEMENT_RULE		= Utilities.BitMask.BIT_1,
}

# Persistent
var combat_edict_demo: int = COMBAT_EDICT_DEMOGRAPHICS.UNSPECIFIED
var combat_edict_category: int = COMBAT_EDICT_CATEGORIES.UNSPECIFIED

func _init():
	Utilities
	pass

func edict_approve(edict) -> bool:
	if "combat_edict_demo" in edict:
		return (edict.combat_edict_demo & combat_edict_demo
			and edict.combat_edict_category & combat_edict_category)
	return true
