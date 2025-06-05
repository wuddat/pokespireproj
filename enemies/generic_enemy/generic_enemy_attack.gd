extends EnemyAction

@export var damage := 2

func setup_from_data(data: Dictionary) -> void:
	var damage_display = "%s"
	damage = data.get("power", 0)
	sound = preload("res://art/sounds/VineWhip2.wav")
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0

	intent = Intent.new()
	intent.base_text = damage_display
	intent.current_text = str(damage)
	if damage <= 5:
		intent.icon = preload("res://art/tile_0103.png")
	elif damage <= 10:
		intent.icon = preload("res://art/tile_0104.png")
	elif damage <= 15:
		intent.icon = preload("res://art/tile_0118.png")
	else:
		intent.icon = preload("res://art/tile_0117.png")

func perform_action() -> void:
	var targets_to_hit: Array[Node] = []

	if targets.size() > 0:
		# Multi-target mode (e.g., Razor Leaf)
		for t in targets:
			if is_instance_valid(t):
				targets_to_hit.append(t)
	else:
		# Fallback to single target
		if not is_instance_valid(target):
			print("Invalid target detected. Attempting to retarget...")
			if enemy and enemy.enemy_action_picker:
				enemy.enemy_action_picker.select_valid_target()
				target = enemy.enemy_action_picker.target

		if is_instance_valid(target):
			targets_to_hit.append(target)
		else:
			print("Still no valid target. Skipping action.")
			Events.enemy_action_completed.emit(enemy)
			return

	animate_to_targets(targets_to_hit, 0, damage)

func update_intent_text() -> void:
	if not is_instance_valid(target):
		print("update_intent_text(): Target is invalid or freed.")
		return

	var target_pkmn := target as PokemonBattleUnit
	if not target_pkmn:
		return

	var modified_dmg := target_pkmn.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_TAKEN)
	intent.current_text = intent.base_text % modified_dmg
