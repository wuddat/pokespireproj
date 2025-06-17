# event_effect_resolver.gd
extends Node

func apply(effects: Dictionary, char_stats: CharacterStats, run_stats: RunStats) -> void:
	for effect in effects:
		match effect:
			"remove_item":
				_remove_item(effects[effect], run_stats)
			"gain_card":
				_gain_card(effects[effect], char_stats)
			"gain_gold":
				_gain_gold(effects[effect], run_stats)
			"lose_hp":
				_lose_hp(effects[effect], char_stats)
			"gain_random_move_card":
				_gain_random_move_card(char_stats)
			"gain_random_card_of_type":
				_gain_random_card_of_type(effects[effect], char_stats)
			"gain_random_card_of_type_for_pokemon":
				_gain_random_card_of_type_for_pokemon(effects[effect], char_stats)
			"gain_rare_card_of_type_for_pokemon":
				_gain_rare_card_of_type_for_pokemon(effects[effect], char_stats)
			"add_pokemon":
				_add_pokemon(effects[effect], char_stats)
			"gold_percent_cost":
				_apply_gold_percent_cost(effects[effect], run_stats)
			"teach_tm":
				_teach_tm(effects[effect], char_stats)


func _remove_item(item: String, run_stats: RunStats) -> void:
	if item == "pokeball" and run_stats.pokeballs > 0:
		run_stats.pokeballs -= 1


func _gain_card(card_id: String, char_stats: CharacterStats) -> void:
	var card := Utils.create_card(card_id)
	if card:
		char_stats.deck.add_card(card)


func _gain_gold(amount: int, run_stats: RunStats) -> void:
	run_stats.gold += amount


func _lose_hp(amount: int, char_stats: CharacterStats) -> void:
	char_stats.current_hp = max(char_stats.current_hp - amount, 0)
	char_stats.stats_changed.emit()


func _gain_random_move_card(char_stats: CharacterStats) -> void:
	var possible_cards: CardPile= char_stats.get_all_move_cards()
	if possible_cards.is_empty():
		return
	possible_cards.shuffle()
	char_stats.deck.add_card(possible_cards.cards[0])


func _gain_random_card_of_type(type: String, char_stats: CharacterStats) -> void:
	if not MoveData.type_to_moves.has(type):
		push_warning("Unknown type in event: %s" % type)
		return
	
	var move_ids = MoveData.type_to_moves[type]
	move_ids.shuffle()
	
	for move_id in move_ids:
		var card := Utils.create_card(move_id)
		if card:
			char_stats.deck.add_card(card)
			print("Event added card: %s" % card.name)
			return


func _gain_random_card_of_type_for_pokemon(data:Dictionary, char_stats: CharacterStats) -> void:
	var type = data.get("type", "")
	var uid = data.get("uid", "")
	
	if not MoveData.type_to_moves.has(type):
		push_warning("Unknown type: %s" % type)
		return
	
	var move_ids = MoveData.type_to_moves[type]
	move_ids.shuffle()
	
	for move_id in move_ids:
		var card = Utils.create_card(move_id)
		if not card:
			continue
		
		var pkmn = char_stats.current_party.filter(func(p): return p.uid == uid)
		if pkmn.is_empty():
			push_warning("Could not find party pkmn with UID %s" % uid)
			return
		
		var target_pkmn = pkmn[0]
		card.pkmn_owner_uid = target_pkmn.uid
		card.pkmn_owner_name = target_pkmn.species_id
		card.pkmn_icon = target_pkmn.icon
		
		char_stats.deck.add_card(card)
		return


func _gain_rare_card_of_type_for_pokemon(data: Dictionary, char_stats: CharacterStats) -> void:
	var type = data.get("type", "")
	var uid = data.get("uid", "")

	if not MoveData.type_to_moves.has(type):
		push_warning("Unknown type: %s" % type)
		return

	var move_ids = MoveData.type_to_moves[type]
	var rare_moves := []

	for move_id in move_ids:
		var move = MoveData.moves.get(move_id)
		if move and move.get("rarity", "") in ["rare", "uncommon"]:
			rare_moves.append(move_id)

	if rare_moves.is_empty():
		print("⚠️ No rare/uncommon moves found for type: %s" % type)
		return

	rare_moves.shuffle()
	var move_id = rare_moves[0]
	print("🎁 Teaching rare move: %s" % move_id)

	var card = Utils.create_card(move_id)
	if not card:
		print("⚠️ Could not create card for move_id: %s" % move_id)
		return

	var pkmn := char_stats.current_party.filter(func(p): return p.uid == uid)
	if pkmn.is_empty():
		print("⚠️ No Pokémon found with UID: %s" % uid)
		return

	var target = pkmn[0]
	card.pkmn_owner_uid = target.uid
	card.pkmn_owner_name = target.species_id
	card.pkmn_icon = target.icon
	char_stats.deck.add_card(card)
	print("✅ Added rare move %s to %s's deck" % [move_id, target.species_id])



func _add_pokemon(species_id: String, char_stats: CharacterStats) -> void:
	var new_pkmn := Pokedex.create_pokemon_instance(species_id)
	if new_pkmn:
		Events.added_pkmn_to_party.emit(new_pkmn)


func _apply_gold_percent_cost(percent: int, run_stats: RunStats) -> void:
	var loss := int(run_stats.gold * percent / 100.0)
	run_stats.gold = max(0, run_stats.gold - loss)


func _teach_tm(data: Dictionary, char_stats: CharacterStats) -> void:
	var move_id = data.get("move_id", "")
	var uid = data.get("uid", "")

	var card = Utils.create_card(move_id)
	if not card:
		return

	var pkmn := char_stats.current_party.filter(func(p): return p.uid == uid)
	if pkmn.is_empty():
		return

	var target = pkmn[0]
	card.pkmn_owner_uid = target.uid
	card.pkmn_owner_name = target.species_id
	card.pkmn_icon = target.icon
	char_stats.deck.add_card(card)
