extends SquadronFormation

func _ready():
	center = $Center
	member_list = {
	"P0": $Center/P0,
	"P1": $Center/P1
}
