# attack.gd
extends Card

func get_default_tooltip() -> String:
	if tooltip_text.find("%") != -1:
		return tooltip_text % str(base_power)
	else:
		return tooltip_text

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler, targets: Array[Node]) -> String:
	var mod_dmg: int = base_power
	if player_modifiers:
		mod_dmg = player_modifiers.get_modified_value(base_power, Modifier.Type.DMG_DEALT)
		
	if enemy_modifiers:
		mod_dmg = enemy_modifiers.get_modified_value(mod_dmg, Modifier.Type.DMG_TAKEN)
		
	# Check for conditional bonus
	if bonus_damage_if_target_has_status != "":
		for tar in targets:
			var handler = tar.get_node_or_null("StatusHandler")
			if handler and handler.has_status(bonus_damage_if_target_has_status):
				mod_dmg *= bonus_damage_multiplier
				break
				
	if targets and is_instance_valid(targets[0]) and (targets[0] is PokemonBattleUnit or targets[0] is Enemy):
		var type_multiplier = TypeChart.get_multiplier(damage_type, targets[0].stats.type)
		mod_dmg = round(mod_dmg * type_multiplier)

	if lead_enabled:
		return "[color=goldenrod]LEAD: [/color]" + tooltip_text % mod_dmg
	else:
		if tooltip_text.find("%") != -1 and mod_dmg:
			return tooltip_text % str(mod_dmg)
		else:
			return tooltip_text

func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	if targets.is_empty():
		return

	# Validate move data
	var move_data = MoveData.moves.get(id)
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return

	# Filter valid targets and check requirements
	var valid_targets = _get_valid_targets(targets, battle_unit_owner)
	if valid_targets.is_empty():
		return

	# Separate primary and splash targets
	var primary_targets: Array[Node] = valid_targets
	var splash_targets: Array[Node] = []
	
	if splash_damage > 0:
		splash_targets = targets.slice(1)
		primary_targets = [targets[0]]

	# Calculate damage amounts
	var target_damage = _calculate_target_damage(primary_targets[0] if primary_targets.size() > 0 else null)
	

	# Execute primary damage
	var total_damage_dealt = EffectExecutor.execute_damage(
		target_damage, 
		primary_targets, 
		battle_unit_owner, 
		modifiers,
		damage_type,
		sound
	)
	
	# Execute splash damage
	if splash_damage > 0 and splash_targets.size() > 0:
		var splash_dealt = EffectExecutor.execute_damage(
			splash_damage,
			splash_targets,
			battle_unit_owner,
			modifiers,
			damage_type,
			sound,
			true
		)
		total_damage_dealt += splash_dealt

	# Handle critical hits
	_handle_critical_hit(battle_unit_owner)
	
	# Apply status effects to targets
	EffectExecutor.execute_status_effects(status_effects, valid_targets, battle_unit_owner, effect_chance)
	
	# Apply shift effects
	if shift_enabled > 0:
		EffectExecutor.execute_shift(valid_targets, battle_unit_owner, shift_enabled)
	
	# Apply self effects
	EffectExecutor.execute_self_effects(
		battle_unit_owner,
		self_damage,
		self_damage_percent_hp,
		self_heal,
		self_block,
		self_status,
		modifiers,
		total_damage_dealt
	)
	
	#Apply Global Effects
	if card_draw:
		EffectExecutor.execute_card_draw(card_draw)

# Helper functions
func _get_valid_targets(targets: Array[Node], battle_unit_owner: PokemonBattleUnit) -> Array[Node]:
	var valid_targets: Array[Node] = []
	
	for tar in targets:
		if not is_instance_valid(tar):
			continue
			
		# Check status requirements
		if requires_status != "":
			if requires_status == "sleep" and not tar.is_asleep:
				continue
			elif requires_status != "sleep":
				var status_handler = tar.get_node_or_null("StatusHandler")
				if not status_handler or not status_handler.has_status(requires_status):
					continue
					
		valid_targets.append(tar)
		
	return valid_targets

func _calculate_target_damage(target: Node) -> int:
	var damage = base_power
	
	if target and target_damage_percent_hp > 0:
		damage = round(target.stats.health * target_damage_percent_hp)
		
	# Apply conditional status bonus
	if bonus_damage_if_target_has_status != "" and target:
		var handler = target.get_node_or_null("StatusHandler")
		if handler and handler.has_status(bonus_damage_if_target_has_status):
			damage *= bonus_damage_multiplier
			
	return damage

func _handle_critical_hit(battle_unit_owner: PokemonBattleUnit) -> void:
	if battle_unit_owner and battle_unit_owner.status_handler.has_status("critical"):
		battle_unit_owner.status_handler.has_and_consume_status("critical")
		var crit_mod = battle_unit_owner.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
		if crit_mod:
			crit_mod.remove_value("critical")
			Events.battle_text_requested.emit("It's a [color=goldenrod]CRITICAL HIT[/color]!")
