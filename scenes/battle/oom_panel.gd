class_name OOMPanel
extends PanelContainer

var tween: Tween
var button_tween: Tween

@onready var end_turn_button: Button = %EndTurnButton
func hide_oom() -> void:
	if button_tween and button_tween.is_running():
		button_tween.kill()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), .2)
	await tween.finished
	hide()
	
func show_oom() -> void:
	if button_tween and button_tween.is_running():
		button_tween.kill()
	show()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,1), .2)
	await tween.finished
	button_tween = create_tween()
	button_tween.set_loops()
	button_tween.tween_property(end_turn_button, "scale", Vector2(1.2,1.2), 0.5).set_ease(Tween.EASE_IN_OUT)
	button_tween.tween_property(end_turn_button, "scale", Vector2(1,1), 0.5).set_ease(Tween.EASE_IN_OUT)
