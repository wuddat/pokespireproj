#status.gd
extends Card

var action_delay = 0.2 #delay between actions

func get_default_tooltip() -> String:
	return tooltip_text % base_power

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler, targets: Array[Node]) -> String:
	var mod_dmg = base_power
	if player_modifiers:
		mod_dmg = player_modifiers.get_modified_value(base_power, Modifier.Type.DMG_DEALT)
		
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

	mod_dmg = 0
	if tooltip_text.find("%") != -1:
		return tooltip_text % str(mod_dmg)
	else:
		return tooltip_text


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	if targets.is_empty():
		return
	
	var move_data = MoveData.moves.get(id)
	var base_damage = 0
	var primary_target = targets[0]
	var _splash_targets: Array[Node]
	var _battle_text: Array[String] = []

	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
	print([targets])
	if splash_damage > 0:
		_splash_targets = targets.slice(1)
	
	
	var _final_damage = base_damage
	var _final_splash = splash_damage
	var total_damage_dealt = 0

# Check for conditional bonus

	#Primary Hit
	if is_instance_valid(primary_target):
		if primary_target.has_method("dodge_check") and !primary_target.dodge_check():
			for status_effect in status_effects:
				await battle_unit_owner.get_tree().create_timer(action_delay).timeout
				if status_effect:
					var stat_effect := StatusEffect.new()
					stat_effect.source = battle_unit_owner
					var status_to_apply := status_effect.duplicate()
					stat_effect.status = status_to_apply
					stat_effect.sound = sound
					stat_effect.execute(targets)
			#This was deactivated to prevent 1 damage from occuring due to minimums set in damage_effect
			#var damage_effect := DamageEffect.new()
			#damage_effect.amount = 0
			#damage_effect.sound = sound
			#damage_effect.execute(targets)
			
			if shift_enabled > 0 and targets.size() > 0:
				var shift_effect := ShiftEffect.new()
				shift_effect.tree = battle_unit_owner.get_tree()
				shift_effect.amount = shift_enabled
				shift_effect.execute(targets)
				
			#user recoil damage if any
			if self_damage > 0:
				var self_dmg_effect := DamageEffect.new()
				self_dmg_effect.amount = self_damage
				self_dmg_effect.sound = null
				self_dmg_effect.execute([battle_unit_owner])
				total_damage_dealt += self_dmg_effect.amount
				
			if self_damage_percent_hp > 0:
				var self_dmg := DamageEffect.new()
				self_dmg.amount = battle_unit_owner.stats.max_health * self_damage_percent_hp
				self_dmg.sound = null
				self_dmg.execute([battle_unit_owner])
				total_damage_dealt += self_dmg.amount
			
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
					self_effect.source = battle_unit_owner
					var status_to_apply := self_stat.duplicate()
					self_effect.status = status_to_apply
					self_effect.execute([battle_unit_owner])
	else: return
