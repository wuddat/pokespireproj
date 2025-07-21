# enemy_block_action.gd
class_name EnemyBlockAction
extends BaseEnemyAction

func setup_from_data(data: Dictionary) -> void:
	super.setup_from_data(data)
	intent_type = "Block"
	intent.icon = preload("res://art/tile_0102.png")
	sound = preload("res://art/block.ogg")
	
	intent.base_text = ""
	intent.current_text = ""

func perform_action() -> void:
	if not enemy or not is_instance_valid(target):
		if enemy and enemy.enemy_action_picker:
			enemy.enemy_action_picker.select_valid_target()
			target = enemy.enemy_action_picker.target

		if not is_instance_valid(target):
			Events.enemy_action_completed.emit(enemy)
			return

	EffectExecutor.execute_block(block_amount, [enemy], enemy, enemy.modifier_handler, sound)
	EffectExecutor.execute_status_effects(status_effects, [target], enemy, 1.0)
	apply_self_effects(0)
	Events.enemy_action_completed.emit(enemy)

func _update_intent_damage_display(target_pkmn: Node) -> void:
	# Block actions don't show damage
	pass
