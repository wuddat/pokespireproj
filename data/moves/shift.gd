# shift.gd
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

func apply_effects(_targets: Array[Node], modifiers: ModifierHandler, battle_unit_owner: PokemonBattleUnit) -> void:
	# Execute the shift effect
	EffectExecutor.execute_shift([battle_unit_owner], battle_unit_owner, 1)
	
	# Emit party shifted event
	Events.party_shifted.emit()
	
	# Update enemy intents (this logic should be moved to a signal handler eventually)
	_update_enemy_intents(battle_unit_owner.get_tree())

func _update_enemy_intents(tree: SceneTree) -> void:
	var enemy_handler = tree.get_first_node_in_group("enemy_handler")
	if not enemy_handler:
		return
		
	for child in enemy_handler.get_children():
		if child.has_method("update_action"):
			child.update_action()
		if child.current_action:
			child.current_action.update_intent_text()
		if child.intent_ui:
			child.intent_ui.update_intent(child.current_action)
