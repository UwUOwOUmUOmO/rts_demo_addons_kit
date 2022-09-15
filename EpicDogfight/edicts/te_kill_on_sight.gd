extends CombatEdict

class_name EdictKOS

const SQUACON_SIGNALS_LIST := {
	"__new_vehicle_added": "new_vehicle_handler"
}

func _init():
	name = "EdictKOS"
	edict_name = "Kill on Sight"
	edict_description = "Engage upon target identification"
	combat_edict_demo = COMBAT_EDICT_DEMOGRAPHICS.MULTIGRADES
	combat_edict_category = COMBAT_EDICT_CATEGORIES.ENGAGEMENT_RULE

func _boot():
	if not current_machine.has_method("__edict_issued"):
		return
	if current_machine.grade > 0:
		# Team level
		if current_machine.host is SquadronController:
			Utilities.SignalTools.connect_from(current_machine.host, self, \
				SQUACON_SIGNALS_LIST)
	current_machine.issue_edict(self)

func new_vehicle_handler(vehicle):
	if not vehicle is CombatantController:
		return
