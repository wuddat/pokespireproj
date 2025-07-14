class_name ItemSlotUI
extends TextureButton

@onready var label: Label = %Label

@export var item: Item


func update_item(value: Item) -> void:
	item = value
	texture_normal = item.icon
	label.text = str(item.quantity)
	label.visible = item.quantity > 1
	
	

func get_tooltip_data() -> Dictionary:
	var slot_header: String
	var slot_description: String = ""
	
	if item == null:
		slot_header= "[color=tan]Items[/color]:"
		slot_description= "When  you  find  some\nyou  can  use  them  to\ndo stuff!"
	else:
		slot_header = "[color=tan]%s[/color]" % item.name
		slot_description = "%s" % item.description
	return {
		"header": slot_header,
		"description": slot_description
	}
