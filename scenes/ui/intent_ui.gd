class_name IntentUI
extends Control


@onready var icon: TextureRect = $HBoxContainer2/HBoxContainer/Icon
@onready var label: Label = $HBoxContainer2/HBoxContainer/Label
@onready var target: TextureRect = $HBoxContainer2/Target



func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return
	
	icon.texture = intent.icon
	icon.visible = icon.texture != null
	label.text = str(intent.current_text)
	label.visible = intent.current_text.length() > 0
	target.texture = intent.target
	target.visible = target.texture != null
	show()
	
