#shift.gd
extends Card


func get_default_tooltip() -> String:
	return tooltip_text % base_power

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler, targets: Array[Node]) -> String:
		var mod_dmg := player_modifiers.get_modified_value(base_power, Modifier.Type.DMG_DEALT)
		
		if enemy_modifiers:
			mod_dmg = enemy_modifiers.get_modified_value(mod_dmg, Modifier.Type.DMG_TAKEN)
		
		# Check for conditional bonus
		if bonus_damage_if_target_has_status != "":
			for tar in targets:
				var handler = tar.get_node_or_null("StatusHandler")
				if handler:
					var statuses = handler.get_statuses()
					print("statuses on unit are: %s" % [statuses])
					for status in statuses:
						if status.id == bonus_damage_if_target_has_status:
							mod_dmg *= bonus_damage_multiplier
							break

		
		return tooltip_text % mod_dmg


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	#var _move_data = MoveData.moves.get(id)
	var tree := battle_unit_owner.get_tree()
	var party_handler = tree.get_first_node_in_group("party_handler")
	party_handler.shift_active_party()
	Events.party_shifted.emit()
	
	var enemy_handler = tree.get_first_node_in_group("enemy_handler") # Or however your picker is grouped
	if enemy_handler:
		for child in enemy_handler.get_children():
			await child.update_action()
			child.current_action.update_intent_text()
			await child.intent_ui.update_intent(child.current_action.intent)
			print("SHIFT.GD enemy attack target is: %s " % child.current_action.target.stats.species_id)
