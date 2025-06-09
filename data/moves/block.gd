extends Card


func get_default_tooltip() -> String:
	return tooltip_text % base_power

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	var mod_block := player_modifiers.get_modified_value(base_power, Modifier.Type.BLOCK_GAINED)

	return tooltip_text % mod_block


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var move_data = MoveData.moves.get(id)
	var base_block = base_power
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
		
	var block_effect := BlockEffect.new()
	block_effect.amount = modifiers.get_modified_value(base_block, Modifier.Type.BLOCK_GAINED)
	block_effect.sound = sound
	block_effect.execute(targets)

	for status_effect in status_effects:
		if status_effect:
			var stat_effect := StatusEffect.new()
			var status_to_apply := status_effect.duplicate()
			stat_effect.status = status_to_apply
			stat_effect.execute(targets)
