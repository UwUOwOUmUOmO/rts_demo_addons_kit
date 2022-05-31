tool
extends BTGraphNode

onready var cycle_option := $VBoxContainer/HBoxContainer/OptionButton

func _ready():
	cycle_option.add_item("Physics")
	cycle_option.add_item("Idle")

func _on_NBT_close_request():
	queue_free()


func _on_NBT_raise_request():
	emit_signal("raised", self)
