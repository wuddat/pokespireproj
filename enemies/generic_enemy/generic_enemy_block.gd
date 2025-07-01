extends EnemyAction

@export var block := 2
@export var description: String

func setup_from_data(data: Dictionary) -> void:
	block = data.get("power", 1)
	sound = preload("res://art/block.ogg")
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0
	action_name = data.get("name", "SOMETHING!")
	description = data.get("description", "SOMETHING!")
	intent = Intent.new()
	intent.icon = preload("res://art/tile_0102.png")  # 🛡️ block icon
	intent.particles_on = false
	intent_type = "Block"

func perform_action() -> void:
	if not enemy or not is_instance_valid(target):
		if enemy and enemy.enemy_action_picker:
			enemy.enemy_action_picker.select_valid_target()
			target = enemy.enemy_action_picker.target

		if not is_instance_valid(target):
			Events.enemy_action_completed.emit(enemy)
			return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])

	get_tree().create_timer(0.6, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)

func update_intent_text() -> void:
	var target_pkmn := target
	if not target_pkmn:
		return
	intent.target = target_pkmn.stats.icon
	
	if block > 0:
		intent.current_text = intent.base_text % block
	else: 
		intent.current_text = intent.base_text % " "

	if enemy and enemy.status_handler.has_status("confused"):
		intent.target = preload("res://art/statuseffects/confused-effect.png")
		return
	
