#attack.gd
extends Card


func get_default_tooltip() -> String:
	return tooltip_text % base_power

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler, targets: Array[Node]) -> String:
	var mod_dmg := await player_modifiers.get_modified_value(base_power, Modifier.Type.DMG_DEALT)
		
	if enemy_modifiers:
		mod_dmg = enemy_modifiers.get_modified_value(mod_dmg, Modifier.Type.DMG_TAKEN)
		
		# Check for conditional bonus
	if bonus_damage_if_target_has_status != "":
		for target in targets:
			var handler = target.get_node_or_null("StatusHandler")
			if handler:
				var statuses = handler.get_statuses()
				print("statuses on unit are: %s" % [statuses])
				for status in statuses:
					if status.id == bonus_damage_if_target_has_status:
						mod_dmg *= bonus_damage_multiplier
						break

		
	return tooltip_text % mod_dmg


func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	if targets.is_empty():
		return
	
	var move_data = MoveData.moves.get(id)
	var base_damage = base_power
	var primary_target = targets[0]
	var splash_targets: Array[Node]
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
	print([targets])
	if splash_damage > 0:
		splash_targets = targets.slice(1)
	
	
	var final_damage = base_damage
	var final_splash = splash_damage
	var total_damage_dealt = 0

# Check for conditional bonus
	# Check for conditional bonus
	if bonus_damage_if_target_has_status != "":
		for target in targets:
			var handler = target.get_node_or_null("StatusHandler")
			if handler:
				var statuses = handler.get_statuses()
				print("statuses on unit are: %s" % [statuses])
				for status in statuses:
					if status.id == bonus_damage_if_target_has_status:
						final_damage *= bonus_damage_multiplier
						break

	#Primary Hit
	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(final_damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	total_damage_dealt += damage_effect.amount
	if targets.size() < 2:
		damage_effect.execute([primary_target])
	else: damage_effect.execute(targets)
		
	
	#Splash Hit
	for splash_target in splash_targets:
		var splash_effect := DamageEffect.new()
		splash_effect.amount = modifiers.get_modified_value(final_splash, Modifier.Type.DMG_DEALT)
		splash_effect.execute([splash_target])
		total_damage_dealt += splash_effect.amount
		print("the execute has been executed for splash")
	
	if battle_unit_owner != null:
		if battle_unit_owner.status_handler.has_status("critical"):
			battle_unit_owner.status_handler.has_and_consume_status("critical")
			var dmg_dealt_mod := battle_unit_owner.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
			if dmg_dealt_mod:
				dmg_dealt_mod.remove_value("critical")
				print("critical consumed")

	
	#apply status effect if any to ALL ENEMIES
	for status_effect in status_effects:
		if status_effect:
			var stat_effect := StatusEffect.new()
			var status_to_apply := status_effect.duplicate()
			stat_effect.status = status_to_apply
			stat_effect.execute(targets)
		
	#user recoil damage if any
	if self_damage > 0:
		var self_dmg_effect := DamageEffect.new()
		self_dmg_effect.amount = self_damage
		self_dmg_effect.sound = null
		self_dmg_effect.execute([battle_unit_owner])
		total_damage_dealt += self_dmg_effect.amount
	
	if self_heal > 0:
		var self_heal_effect := HealEffect.new()
		self_heal_effect.amount = total_damage_dealt/2
		#TODO add heal effect sfx
		self_heal_effect.sound = null
		self_heal_effect.execute([battle_unit_owner])
		
	#status effects on user if any
	for self_stat in self_status:
		if self_stat:
			var self_effect := StatusEffect.new()
			var status_to_apply := self_stat.duplicate()
			self_effect.status = status_to_apply
			self_effect.execute([battle_unit_owner])
	Utils.print_resource(self)
