class_name CombatText
extends Control

@onready var label: Label = $Label
@onready var anim: AnimationPlayer = $AnimationPlayer

func show_text(content: String, color: Color = Color.WHITE):
	label.text = content
	label.modulate = color
	anim.play("rise_and_fade") # this animation will move & fade the label


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "rise_and_fade":
		queue_free()
