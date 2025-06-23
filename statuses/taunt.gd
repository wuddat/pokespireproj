class_name Taunt
extends Status

func get_tooltip() -> String:
	return "This unit was TAUNTED!"

func initialize_status(target: Node) -> void:
	if not (target is Enemy):
		return

	var enemy_target := target as Enemy
	if enemy_target.status_handler:
		if enemy_target.current_action:
			var enemy_action_picker = enemy_target.enemy_action_picker
			enemy_action_picker.current_target_pos = status_source.spawn_position
			for action in enemy_action_picker.get_children():
				action.target = status_source
			enemy_action_picker.target = status_source
			enemy_target.current_action.target = status_source
			print("[TAUNTED ENEMY] updated enemy target to: ", enemy_target.current_action.target.stats.species_id)
	enemy_target.current_action.update_intent_text()
	SFXPlayer.play(preload("res://art/enemy_block.ogg"))
	enemy_target.status_handler.remove_status("taunt")
