# enemy_attack_action.gd
class_name EnemyAttackAction
extends BaseEnemyAction

func setup_from_data(data: Dictionary) -> void:
	super.setup_from_data(data)
	intent_type = "Attack"
	
	# Attack-specific intent setup
	if damage <= 5:
		intent.icon = preload("res://art/tile_0103.png")
	elif damage > 5 and damage <= 10:
		intent.icon = preload("res://art/tile_0104.png")
	elif damage > 10 and damage <= 15:
		intent.icon = preload("res://art/tile_0118.png")
	else:
		intent.icon = preload("res://art/tile_0117.png")
	
	if not sound:
		sound = load("res://art/axe.ogg")

func perform_action() -> void:
	var targets_to_hit = get_valid_targets()
	if targets_to_hit.is_empty():
		Events.enemy_action_completed.emit(enemy)
		return
	
	var final_damage = calculate_damage(targets_to_hit[0] if targets_to_hit.size() > 0 else null)
	var primary_targets = targets_to_hit
	var splash_targets: Array[Node] = []
	
	if splash_damage > 0:
		splash_targets = targets_to_hit.slice(1)
		primary_targets = [targets_to_hit[0]]
	
	# Animate and execute effects
	#await EffectExecutor.execute_enemy_animation(enemy, primary_targets, final_damage)
	
	var total_damage_dealt = EffectExecutor.execute_enemy_damage(
		final_damage, primary_targets, enemy, damage_type, sound
	)
	
	if splash_damage > 0 and splash_targets.size() > 0:
		total_damage_dealt += EffectExecutor.execute_enemy_damage(
			splash_damage, splash_targets, enemy, damage_type
		)
	
	EffectExecutor.execute_status_effects(status_effects, targets_to_hit, enemy, 1.0)
	
	if shift_enabled > 0:
		EffectExecutor.execute_shift(targets_to_hit, enemy, shift_enabled)
	
	apply_self_effects(total_damage_dealt)
	Events.enemy_action_completed.emit(enemy)
