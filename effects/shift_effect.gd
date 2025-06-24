# shift_effect.gd
class_name ShiftEffect
extends Effect

var amount := 1  # How many slots to shift (default 1)

func execute(targets: Array[Node]) -> void:
	if not is_instance_valid(targets[0]):
		return
	if not tree:
		push_warning("ShiftEffect could not find parent TREE")
		return
	if targets[0] is PokemonBattleUnit:
		print("target is PKMNBATTLEUNIT")
		var party_handler = tree.get_first_node_in_group("party_handler")
		if party_handler:
			for i in amount:
				party_handler.shift_active_party()
		Events.party_shifted.emit()

		# Optional: Update enemy intents if needed
		var enemy_handler = tree.get_first_node_in_group("enemy_handler")
		if enemy_handler:
			for child in enemy_handler.get_children():
				if child.has_method("update_action"):
					await child.update_action()
				if child.current_action:
					child.current_action.update_intent_text()
				if child.intent_ui:
					await child.intent_ui.update_intent(child.current_action.intent)
					
	elif targets[0] is Enemy:
		print("target is ENEMY")
		var enemy_handler = tree.get_first_node_in_group("enemy_handler")
		if enemy_handler:
			enemy_handler.shift_enemies()
			Events.party_shifted.emit()
			for child in enemy_handler.get_children():
				if child.has_method("update_action"):
					await child.update_action()
				if child.current_action:
					child.current_action.update_intent_text()
				if child.intent_ui:
					await child.intent_ui.update_intent(child.current_action.intent)
		
	else:
		print("❌ SHIFT EFFECT FAILED — target was neither PKMN nor Enemy")
