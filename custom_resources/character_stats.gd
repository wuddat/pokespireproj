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

@export_group("Pokemon Data")
@export var starting_party: Array[String] = []

var current_party: Array[PokemonStats] = []
var mana : int : set = set_mana
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile
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
	
	for species_id in starting_party:
		var pkmn = Pokedex.create_pokemon_instance(species_id)
		if pkmn:
			instance.current_party.append(pkmn)
			print("pokemon loaded from dex: %s " % pkmn.species_id)
			
		else:
			print("Missing Pokedex data for %s" % species_id)
			
	instance.deck = build_deck_from_move_ids(starting_moves)
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	instance.draftable_cards = build_deck_from_move_ids(draftable_move_ids)
	return instance

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

func update_draftable_cards() -> void:
	draftable_cards.cards.clear()

	var new_draft_list : Array[String]

	for pkmn in current_party:
		var move_list = pkmn.get_draft_cards_from_type()
		new_draft_list.append_array(move_list)
	
	var pkmn_draft_list: CardPile = build_deck_from_move_ids(new_draft_list)
	draftable_cards = pkmn_draft_list
