#status.gd
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
	if targets:
		var target_types = targets[0].stats.type
		var type_multiplier = Effectiveness.get_multiplier(damage_type, target_types)
		mod_dmg *= type_multiplier
		mod_dmg = round(mod_dmg)

	mod_dmg = 0
	return tooltip_text % mod_dmg


func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	if targets.is_empty():
		return
	
	var move_data = MoveData.moves.get(id)
	var base_damage = 0
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

	#Primary Hit
	if is_instance_valid(primary_target):
		
		for status_effect in status_effects:
			if status_effect:
				var stat_effect := StatusEffect.new()
				var status_to_apply := status_effect.duplicate()
				stat_effect.status = status_to_apply
				stat_effect.execute(targets)
		
		var damage_effect := DamageEffect.new()
		damage_effect.amount = 0
		damage_effect.sound = sound
		damage_effect.execute(targets)
			
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
	else: return
