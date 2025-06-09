extends Card


func get_default_tooltip() -> String:
	return tooltip_text % base_power

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
		var mod_dmg := player_modifiers.get_modified_value(base_power, Modifier.Type.DMG_DEALT)
		
		if enemy_modifiers:
			mod_dmg = enemy_modifiers.get_modified_value(mod_dmg, Modifier.Type.DMG_TAKEN)
		
		return tooltip_text % mod_dmg


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var move_data = MoveData.moves.get(id)
	var base_damage = base_power
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
	
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(base_damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute(targets)
	
	if self.status_handler.has_status("critical"):
		self.status_handler.remove_status("critical")
	
	
	#apply status effect if any on card
	for status_effect in status_effects:
		if status_effect:
			var stat_effect := StatusEffect.new()
			var status_to_apply := status_effect.duplicate()
			stat_effect.status = status_to_apply
			stat_effect.execute(targets)
