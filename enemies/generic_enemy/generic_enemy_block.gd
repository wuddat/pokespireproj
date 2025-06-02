extends EnemyAction

@export var block := 2

func setup_from_data(data: Dictionary) -> void:
	block = data.get("power", 1)
	#print("data passed to setup as: ",data)
	sound = preload("res://art/block.ogg")
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0
	
	intent = Intent.new()
	intent.number = str(block)
	intent.icon = preload("res://art/tile_0102.png")


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
