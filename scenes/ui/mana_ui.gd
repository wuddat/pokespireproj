class_name ManaUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var mana_label: Label = $ManaLabel
@onready var end_turn_button: Button = %EndTurnButton

var button_tween: Tween
var battle_start: bool = false


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	
	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)
	
	if not is_node_ready():
		await ready
	

	_on_stats_changed()


func _on_stats_changed() -> void:
	await get_tree().create_timer(.1).timeout
	if char_stats.mana == null or char_stats.max_mana == null:
		return
	mana_label.text = "%s/%s" % [char_stats.mana, char_stats.max_mana]
	if char_stats.mana >= 1 or battle_start == false and end_turn_button.disabled != true:
		battle_start = true
		if button_tween and button_tween.is_running():
			button_tween.kill()
		return
	else:
		print("mana is: ", char_stats.mana)
		if button_tween and button_tween.is_running():
			button_tween.kill()
		button_tween = create_tween()
		button_tween.set_loops()
		button_tween.tween_property(end_turn_button, "scale", Vector2(1.2,1.2), 0.5).set_ease(Tween.EASE_IN_OUT)
		button_tween.tween_property(end_turn_button, "scale", Vector2(1,1), 0.5).set_ease(Tween.EASE_IN_OUT)
