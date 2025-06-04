extends Card


func get_default_tooltip() -> String:
	return tooltip_text % base_power


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text % base_power


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var move_data = MoveData.moves.get(id)
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
		
	var block_effect := BlockEffect.new()
	block_effect.amount = move_data.get("power" , 0)
	block_effect.sound = sound
	block_effect.execute(targets)
