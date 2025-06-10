class_name Shop
extends Control

const SHOP_CARD = preload("res://scenes/shop/shop_card.tscn")
const SHOP_PKMN = preload("res://scenes/shop/shop_pkmn.tscn")

@export var shop_pkmn: Array[PokemonStats]
@export var char_stats: CharacterStats
@export var run_stats: RunStats

@onready var cards: HBoxContainer = %Cards
@onready var card_detail_overlay: CardDetailOverlay = %CardDetailOverlay
@onready var pokemon: HBoxContainer = %Pokemon

func _ready() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.queue_free()
	
	for shop_pkmn: ShopPkmn in pokemon.get_children():
		shop_pkmn.queue_free()
	
	Events.shop_card_bought.connect(_on_shop_card_bought)
	Events.shop_pkmn_bought.connect(_on_shop_pkmn_bought)
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and card_detail_overlay.visible:
		card_detail_overlay.hide_tooltip()

func populate_shop() -> void:
	_generate_shop_cards()
	_generate_shop_pkmn()

func _generate_shop_cards() -> void:
	var shop_card_array: Array[Card] = []
	var available_cards := char_stats.draftable_cards.cards.duplicate(true)
	available_cards.shuffle()
	shop_card_array = available_cards.slice(0,5)
	
	for card: Card in shop_card_array:
		var new_shop_card := SHOP_CARD.instantiate() as ShopCard
		cards.add_child(new_shop_card)
		new_shop_card.card = card
		new_shop_card.current_card_ui.tooltip_requested.connect(card_detail_overlay.show_tooltip)
		new_shop_card.update(run_stats)


func _generate_shop_pkmn() -> void:
	var shop_pkmn_array: Array[PokemonStats] = []

	# Step 1: Get a shuffled list of available species IDs from your pokedex
	var species_ids = Pokedex.pokedex.keys()
	species_ids.shuffle()
	var selected_ids = species_ids.slice(0, 3)  # Pick 3 random Pokémon for the shop

	# Step 2: Generate stats for each selected Pokémon
	for species_id in selected_ids:
		var pkmn_stats := Pokedex.create_pokemon_instance(species_id)
		if pkmn_stats:
			shop_pkmn_array.append(pkmn_stats)

	# Step 3: Store it in your exported array so it's accessible later
	shop_pkmn = shop_pkmn_array

	# Step 4: Display them in the shop UI
	for pkmn: PokemonStats in shop_pkmn_array:
		var new_shop_pkmn := SHOP_PKMN.instantiate() as ShopPkmn
		pokemon.add_child(new_shop_pkmn)
		new_shop_pkmn.pkmn = pkmn
		new_shop_pkmn.update(run_stats)

func _update_items() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.update(run_stats)
	
	for shop_pkmn: ShopPkmn in pokemon.get_children():
		shop_pkmn.update(run_stats)

func _on_back_button_pressed() -> void:
	Events.shop_exited.emit()


func _on_shop_card_bought(card: Card, gold_cost: int) -> void:
	char_stats.deck.add_card(card)
	run_stats.gold -= gold_cost
	_update_items()

func _on_shop_pkmn_bought(pkmn: PokemonStats, gold_cost: int) -> void:
	char_stats.current_party.append(pkmn)
	run_stats.gold -= gold_cost
	print("added pkmn to party: ", pkmn.species_id)
	Events.added_pkmn_to_party.emit()
