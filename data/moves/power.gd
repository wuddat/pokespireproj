# power.gd
extends Card

func get_default_tooltip() -> String:
	if tooltip_text.find("%") != -1:
		return tooltip_text % str(base_power)
	else:
		return tooltip_text

func get_updated_tooltip(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler, targets: Array[Node]) -> String:
	if tooltip_text.find("%") != -1 and base_power:
		return tooltip_text % str(base_power)
	else:
		return tooltip_text

func apply_effects(targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	if targets.is_empty():
		return
	
	var move_data = MoveData.moves.get(id)
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
	
	var primary_target = targets[0]
	if not is_instance_valid(primary_target):
		return
	
	# Power cards typically apply status effects and buffs
	EffectExecutor.execute_status_effects(status_effects, targets, battle_unit_owner, effect_chance)
	
	# Apply self effects (no damage dealt for power cards)
	EffectExecutor.execute_self_effects(
		battle_unit_owner,
		self_damage,
		self_damage_percent_hp,
		self_heal,
		self_block,
		self_status,
		modifiers,
		0  # No damage dealt for power cards
	)
