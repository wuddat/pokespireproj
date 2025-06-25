#attack.gd
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
	if targets:
		var target_types = targets[0].stats.type
		var type_multiplier = TypeChart.get_multiplier(damage_type, target_types)
		mod_dmg *= type_multiplier
		mod_dmg = round(mod_dmg)

		
	return tooltip_text % mod_dmg


func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	if targets.is_empty():
		return

	var move_data = MoveData.moves.get(id)
	var base_damage = base_power
	var splash_targets: Array[Node]
	var battle_text: Array[String] = [" "]

	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return

	if splash_damage > 0:
		splash_targets = targets.slice(1)
		targets = [targets[0]]

	var final_damage = base_damage
	var final_splash = splash_damage
	var total_damage_dealt = 0

	# 💥 Deal primary damage to each valid target
	for tar in targets:
		if not is_instance_valid(tar):
			continue
		if tar.has_method("dodge_check") and tar.dodge_check():
			continue
		else:
		# ❌ Skip if requires a status the target doesn't have
			if requires_status != "" and requires_status != "sleep":
				var status_handler = tar.get_node_or_null("StatusHandler")
				if not status_handler or not status_handler.has_status(requires_status):
					print("❌ Skipping %s due to missing required status: %s" % [tar.stats.species_id, requires_status])
					continue
			if requires_status == "sleep":
				if !tar.is_asleep:
					print("❌ Skipping %s because target is not asleep (Dream Eater requirement)" % tar.stats.species_id)
					continue

			var handler = tar.get_node_or_null("StatusHandler")
			var target_damage = final_damage
			
			if target_damage_percent_hp > 0:
				target_damage = round(tar.stats.health * target_damage_percent_hp)

			# 🎯 Bonus if target has a specific status
			if bonus_damage_if_target_has_status != "":
				if handler and handler.has_status(bonus_damage_if_target_has_status):
					target_damage *= bonus_damage_multiplier

			var type_multiplier := TypeChart.get_multiplier(damage_type, tar.stats.type)
			var mod_damage := modifiers.get_modified_value(target_damage, Modifier.Type.DMG_DEALT)
			var total = round(mod_damage * type_multiplier)

			var damage_effect := DamageEffect.new()
			damage_effect.amount = total

			# 🎵 Set sound based on effectiveness
			var effective_text: String
			var effectiveness: bool = false
			if type_multiplier > 1:
				damage_effect.sound = preload("res://art/sounds/sfx/supereffective.wav")
				effective_text = "It's [color=goldenrod]SUPER EFFECTIVE[/color]!"
				effectiveness = true
			elif type_multiplier < 1:
				damage_effect.sound = preload("res://art/sounds/not_effective.wav")
				effectiveness = true
				effective_text = "It's not very effective..!"
			else:
				damage_effect.sound = sound
			damage_effect.execute([tar])
			
			if shift_enabled > 0 and targets.size() > 0:
				var shift_effect := ShiftEffect.new()
				shift_effect.tree = battle_unit_owner.get_tree()
				shift_effect.amount = shift_enabled
				shift_effect.execute([tar])

	# 💦 Splash Damage (unaffected by effectiveness or statuses)
		for splash_target in splash_targets:
			if not is_instance_valid(splash_target):
				continue

			var splash_type_multiplier := TypeChart.get_multiplier(damage_type, splash_target.stats.type)
			var splash_modified := modifiers.get_modified_value(final_splash, Modifier.Type.DMG_DEALT)
			var splash_total = round(splash_modified * splash_type_multiplier)

			var splash_effect := DamageEffect.new()
			splash_effect.amount = splash_total
			splash_effect.execute([splash_target])
			total_damage_dealt += splash_total
			print("💦 Splash damage (%s) applied to %s" % [splash_total, splash_target.name])

		# 💣 Critical Modifier Consumption
		if battle_unit_owner and battle_unit_owner.status_handler.has_status("critical"):
			battle_unit_owner.status_handler.has_and_consume_status("critical")
			var crit_mod := battle_unit_owner.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
			if crit_mod:
				crit_mod.remove_value("critical")
				Events.battle_text_requested.emit("It's a [color=goldenrod]CRITICAL HIT[/color]!")
				print("✅ Critical consumed")

		# 🧬 Apply status effects to targets
		for status_effect in status_effects:
			if status_effect:
				var applied = randf() <= effect_chance
				if applied:
					var stat_effect := StatusEffect.new()
					stat_effect.source = battle_unit_owner
					stat_effect.status = status_effect.duplicate()
					stat_effect.execute(targets)
				else:
					print("🎲 %s status failed to apply (%.0f%% chance) and applied was: %s" % [status_effect.id, effect_chance * 100, applied])	
					
		if self_block > 0:
			var block = BlockEffect.new()
			block.amount = self_block
			block.execute([battle_unit_owner])
			
		if dmg_block > 0:
			var block = BlockEffect.new()
			block.amount = total_damage_dealt
			block.execute([battle_unit_owner])
		
		# 🩸 Self damage
		if self_damage > 0:
			var self_dmg := DamageEffect.new()
			self_dmg.amount = self_damage
			self_dmg.sound = null
			self_dmg.execute([battle_unit_owner])
			total_damage_dealt += self_dmg.amount
		
		if self_damage_percent_hp > 0:
			var self_dmg := DamageEffect.new()
			self_dmg.amount = battle_unit_owner.stats.max_health * self_damage_percent_hp
			self_dmg.sound = null
			self_dmg.execute([battle_unit_owner])
			total_damage_dealt += self_dmg.amount

		# 💚 Self heal (half total damage dealt)
		if self_heal > 0:
			var self_heal_effect := HealEffect.new()
			self_heal_effect.amount = total_damage_dealt / 2
			self_heal_effect.sound = null
			self_heal_effect.execute([battle_unit_owner])

		# 🧪 Self status effects
		for self_stat in self_status:
			if self_stat:
				var self_effect := StatusEffect.new()
				self_effect.source = battle_unit_owner
				self_effect.status = self_stat.duplicate()
				self_effect.execute([battle_unit_owner])
		
		if self_shift > 0:
			var shift_effect := ShiftEffect.new()
			shift_effect.tree = battle_unit_owner.get_tree()
			shift_effect.execute([battle_unit_owner])
	emit_dialogue(battle_text)
