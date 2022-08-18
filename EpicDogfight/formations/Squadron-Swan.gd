extends SquadronFormation

func _ready():
	center = $Center
	member_list = {
	"P0": $Center/P0,
	"P1": $Center/P1,
	"P2": $Center/P2,
	"P3": $Center/P3,
	"P4": $Center/P4,
	"P5": $Center/P5,
	"P6": $Center/P6,
	"P7": $Center/P7,
	"P8": $Center/P8,
	"P9": $Center/P9,
}
