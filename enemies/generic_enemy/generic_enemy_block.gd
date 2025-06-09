extends EnemyAction

@export var block := 2

func setup_from_data(data: Dictionary) -> void:
	block = data.get("power", 1)
	sound = preload("res://art/block.ogg")
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0
	
	intent = Intent.new()
	intent.icon = preload("res://art/tile_0102.png")


func perform_action() -> void:
	if not enemy or not is_instance_valid(target):
		print("Invalid target detected. Attempting to retarget...")
		if enemy and enemy.enemy_action_picker:
			enemy.enemy_action_picker.select_valid_target()
			target = enemy.enemy_action_picker.target

		if not is_instance_valid(target):
			print("Still no valid target. Skipping action.")
			Events.enemy_action_completed.emit(enemy)
			return
	
	
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
