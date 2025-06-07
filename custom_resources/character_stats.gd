class_name CharacterStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture
@export var frames: SpriteFrames

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_move_ids: Array[String] =[]
@export var cards_per_turn: int
@export var max_mana: int
@export var starting_moves: Array[String] = []
@export var starting_items: Array[String] = []

@export_group("Pokemon Data")
@export var starting_party: Array[String] = []

var current_party: Array[PokemonStats] = []
var mana : int : set = set_mana
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile
var faint_pile: Dictionary = {} # uid (String) -> CardPile
var battle_deck: CardPile
var draftable_cards: CardPile


func set_mana (value: int) -> void:
	mana = value
	stats_changed.emit()


func reset_mana() -> void:
	mana = max_mana


func take_damage(damage:int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func card_playable(card: Card) -> bool:
	return mana >= card.cost


func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health #TODO update this to equal the number of pokemon in the party
	instance.block = 0
	instance.reset_mana()
	
	instance.current_party = []
	
	for starter in starting_party:
		var pkmn = Pokedex.create_pokemon_instance(starter)
		if pkmn:
			instance.current_party.append(pkmn)
			print("pokemon loaded from dex: %s " % pkmn.species_id)
			
		else:
			print("Missing Pokedex data for %s" % starter)
			
	instance.deck = CardPile.new()
	for pkmn in instance.current_party:
		var pkmn_cards = build_deck_from_starter(pkmn)
		instance.deck.cards.append_array(pkmn_cards.cards)
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	instance.draftable_cards = build_deck_from_move_ids(draftable_move_ids)
	return instance


func get_faint_pile(uid: String) -> CardPile:
	if faint_pile.has(uid):
		return faint_pile[uid]
	else:
		return CardPile.new()


func get_all_party_members() -> Array[PokemonStats]:
	return current_party


func build_deck_from_starter(pkmn: PokemonStats) -> CardPile:
	var pile := CardPile.new()
	var move_to_resource_map = {
		"attack": preload("res://data/moves/attack.tres"),
		"defense": preload("res://data/moves/block.tres"),
		"power": preload("res://data/moves/power.tres")
	}
	
	var move_ids = starting_moves
	for move_id in move_ids:
		var move_data = MoveData.moves.get(move_id)
		if move_data == null:
			continue
		var card_type: Card = move_to_resource_map.get(move_data.get("category", "attack"))
		if card_type == null:
			continue
		var card: Card = card_type.duplicate()
		if card.has_method("setup_from_data"):
			card.setup_from_data(move_data)
		card.pkmn_owner_uid = pkmn.uid
		card.pkmn_icon = pkmn.icon
		card.pkmn_owner_name = pkmn.species_id
		pile.add_card(card)
	move_ids = starting_items
	for move_id in move_ids:
		var move_data = MoveData.moves.get(move_id)
		if move_data == null:
			continue
		var card_type: Card = move_to_resource_map.get(move_data.get("category", "attack"))
		if card_type == null:
			continue
		var card: Card = card_type.duplicate()
		if card.has_method("setup_from_data"):
			card.setup_from_data(move_data)
			pile.add_card(card)
	return pile


func build_deck_from_pokemon(pkmn: PokemonStats) -> CardPile:
	var pile := CardPile.new()
	var move_to_resource_map = {
		"attack": preload("res://data/moves/attack.tres"),
		"defense": preload("res://data/moves/block.tres"),
		"power": preload("res://data/moves/power.tres")
	}
	
	var move_ids = pkmn.move_ids
	for move_id in move_ids:
		var move_data = MoveData.moves.get(move_id)
		if move_data == null:
			continue
		var card_type: Card = move_to_resource_map.get(move_data.get("category", "attack"))
		if card_type == null:
			continue
		var card: Card = card_type.duplicate()
		if card.has_method("setup_from_data"):
			card.setup_from_data(move_data)
		card.pkmn_owner_uid = pkmn.uid
		pile.add_card(card)
	return pile


func build_deck_from_move_ids(move_ids: Array[String]) -> CardPile:
	var pile := CardPile.new()
	
	var move_to_resource_map = {
		"attack": preload("res://data/moves/attack.tres"),
		"defense": preload("res://data/moves/block.tres"),
		"power": preload("res://data/moves/power.tres")
	}

	for move_id in move_ids:
		var move_data = MoveData.moves.get(move_id)
		if move_data == null:
			push_warning("Move ID '%s' not found" % move_id)
			continue
			
		var card_type: Card = move_to_resource_map.get(move_data.get("category", "attack"))
		if card_type == null:
			push_warning("Move ID '%s' for category '%s' " % move_data.get("category"))
			continue
			
		var card := card_type.duplicate()
		if card.has_method("setup_from_data"):
			card.setup_from_data(move_data)
		pile.add_card(card)
		#pile.add_card(preload("res://characters/bulbasaur/cards/bulbasaur_vinewhip.tres"))
		#pile.add_card(preload("res://characters/bulbasaur/cards/powerTest.tres"))
		
	return pile


func build_battle_deck(selected_pokemon: Array[PokemonStats]) -> CardPile:
	var pile := CardPile.new()

	for card in deck.cards:
		var owner_uid := card.pkmn_owner_uid

		var is_active_pokemon_card := selected_pokemon.any(func(pkmn): return pkmn.uid == owner_uid)
		var is_item_card := owner_uid == "" or owner_uid == null

		var not_in_faint_pile = not faint_pile.has(owner_uid) or not faint_pile[owner_uid].cards.has(card)

		if (is_active_pokemon_card or is_item_card) and not_in_faint_pile:
			pile.add_card(card)

	return pile


func update_draftable_cards() -> void:
	draftable_cards.cards.clear()

	var new_draft_list : Array[String]

	for pkmn in current_party:
		var move_list = pkmn.get_draft_cards_from_type()
		new_draft_list.append_array(move_list)
	
	var pkmn_draft_list: CardPile = build_deck_from_move_ids(new_draft_list)
	draftable_cards = pkmn_draft_list


func print_faint_pile():
	for uid in faint_pile.keys():
		print("UID:", uid)
		for card in faint_pile[uid].cards:
			print(" -", card.move_id)
