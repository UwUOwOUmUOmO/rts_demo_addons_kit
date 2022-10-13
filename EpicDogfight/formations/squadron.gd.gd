extends SquadronFormation

func _ready():
	center = get_child(0)
	for c in center.get_children():
		member_list[c.name] = c
