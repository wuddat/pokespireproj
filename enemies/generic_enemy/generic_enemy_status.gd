# enemy_status_action.gd
class_name EnemyStatusAction
extends BaseEnemyAction

func setup_from_data(data: Dictionary) -> void:
	super.setup_from_data(data)
	intent_type = "Status"
	damage = 0  # Status actions don't deal damage
	
	if not sound:
		sound = preload("res://art/sounds/VineWhip2.wav")

func perform_action() -> void:
	var targets_to_hit = get_valid_targets()
	if targets_to_hit.is_empty():
		Events.enemy_action_completed.emit(enemy)
		return

	#await EffectExecutor.execute_enemy_animation(enemy, targets_to_hit, 0)
	EffectExecutor.execute_status_effects(status_effects, targets_to_hit, enemy, 1.0, sound)
	
	if shift_enabled > 0:
		EffectExecutor.execute_shift(targets_to_hit, enemy, shift_enabled)
	
	apply_self_effects(0)
	Events.enemy_action_completed.emit(enemy)
