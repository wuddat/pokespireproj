# event_effect_resolver.gd
#this is a global autoload singleton
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



func _add_pokemon(species_id: String, _char_stats: CharacterStats) -> void:
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


func generate_tm_cards(type: String, count: int, node: Array[Node]) -> Array[Card]:
	var pkmn: PokemonBattleUnit = node[0]
	var result: Array[Card] = []
	if not MoveData.type_to_moves.has(type):
		print("EER: TM generation failed for type %s" % type)
		return result
	var move_ids = MoveData.type_to_moves[type]
	move_ids.shuffle()
	
	move_ids = move_ids.slice(0,3)
	
	for move_id in move_ids:
		var card = Utils.create_card(move_id)
		card.pkmn_owner_uid = pkmn.stats.uid
		card.pkmn_owner_name = pkmn.stats.species_id
		card.pkmn_icon = pkmn.stats.icon
		if card:
			result.append(card)
	
	return result


func _handle_card_gain(effect: String, data: Variant, char_stats: CharacterStats) -> void:
	var card: Card = null
	
	match effect:
		"gain_card":
			card = Utils.create_card(data)

		"gain_random_card_of_type", "gain_random_card_of_type_for_pokemon", "gain_rare_card_of_type_for_pokemon":
			var type = data.get("type", "")
			if not MoveData.type_to_moves.has(type):
				push_warning("Unknown type in event: %s" % type)
				return

			var move_ids = MoveData.type_to_moves[type]

			if effect == "gain_rare_card_of_type_for_pokemon":
				move_ids = move_ids.filter(func(m): 
					return MoveData.moves.get(m, {}).get("rarity", "") in ["rare", "uncommon"]
				)
				if move_ids.is_empty():
					return

			move_ids.shuffle()
			card = Utils.create_card(move_ids[0])

		"teach_tm":
			card = Utils.create_card(data.get("move_id", ""))

	if not card:
		return

	# Assign Pokémon if necessary
	if effect in ["gain_random_card_of_type_for_pokemon", "gain_rare_card_of_type_for_pokemon", "teach_tm"]:
		var uid = data.get("uid", "")
		var pkmn = char_stats.current_party.filter(func(p): return p.uid == uid)
		if pkmn.is_empty():
			push_warning("No Pokémon found for UID %s" % uid)
			return
		var target = pkmn[0]
		card.pkmn_owner_uid = target.uid
		card.pkmn_owner_name = target.species_id
		card.pkmn_icon = target.icon

	char_stats.deck.add_card(card)
	print("✅ Added card: %s" % card.name)


func create_event_card(effects: Dictionary, char_stats: CharacterStats) -> Card:
	var card: Card = null

	for effect in effects:
		match effect:
			"gain_card":
				card = Utils.create_card(effects[effect])
			"gain_random_card_of_type":
				var type = effects[effect]
				if not MoveData.type_to_moves.has(type):
					return null
				card = Utils.create_card(MoveData.type_to_moves[type].pick_random())
			"gain_random_card_of_type_for_pokemon", "gain_rare_card_of_type_for_pokemon", "teach_tm", "imbued_stone":
				var type = effects[effect].get("type", "")
				var move_id = effects[effect].get("move_id", "")
				var uid = effects[effect].get("uid", "")
				
				if effect == "teach_tm":
					card = Utils.create_card(move_id)
				else:
					if not MoveData.type_to_moves.has(type):
						return null
					var candidates = MoveData.type_to_moves[type]
					if effect == "gain_rare_card_of_type_for_pokemon":
						candidates = candidates.filter(func(m): return MoveData.moves.get(m, {}).get("rarity", "") in ["rare", "uncommon"])
						if candidates.is_empty():
							return null
					card = Utils.create_card(candidates.pick_random())
				
				var pkmn = char_stats.current_party.filter(func(p): return p.uid == uid)
				if not pkmn.is_empty():
					var target = pkmn[0]
					card.pkmn_owner_uid = target.uid
					card.pkmn_owner_name = target.species_id
					card.pkmn_icon = target.icon

	return card
