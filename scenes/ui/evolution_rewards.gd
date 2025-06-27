class_name EvolutionReward
extends Control

@onready var cards_to_forget: VBoxContainer = %CardsToForget
@onready var cards_to_learn: VBoxContainer = %CardsToLearn
@onready var forget_slot: CardMenuUI = %ForgetCard
@onready var learn_slot: CardMenuUI = %LearnCard
@onready var confirm_button: Button = %ConfirmButton
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var forget_card_name: Label = %ForgetCardName
@onready var learn_card_name: Label = %LearnCardName
@onready var skip_button: Button = %SkipButton

@export var char_stats: CharacterStats
@export var forgettable_cards: Array[Card] : set = set_forgettable_cards
@export var learnable_cards: Array[Card] : set = set_learnable_cards

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")

var pokemon: PokemonStats
var player_deck = CardPile
var forget_card: Card = null
var learn_card: Card = null
var seen_ids := {}

var forget_slot_selected := false
var learn_slot_selected := false


func _ready() -> void:
	_clear_rewards()
	seen_ids = {}
	print("🟩 EvolutionReward _ready fired")
	confirm_button.pressed.connect(_on_confirm)
	skip_button.pressed.connect(_on_skip)
	
	confirm_button.disabled = true


func set_forgettable_cards(new_cards: Array[Card]) -> void:
	forgettable_cards = new_cards
	confirm_button.disabled = true
	if not is_node_ready():
		await ready
		
	if new_cards.is_empty():
		queue_free()
		
	for card: Card in forgettable_cards:
		if seen_ids.has(card.id):
			continue
		seen_ids[card.id] = true
		var new_card := CARD_MENU_UI.instantiate() as CardMenuUI
		cards_to_forget.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(_on_forget_selected)


func set_learnable_cards(new_cards: Array[Card]) -> void:
	learnable_cards = new_cards
	
	if not is_node_ready():
		await ready
	
	if new_cards.is_empty():
		queue_free()
		
	for card: Card in learnable_cards:
		if seen_ids.has(card.id):
			continue
		seen_ids[card.id] = true
		var new_card := CARD_MENU_UI.instantiate() as CardMenuUI
		cards_to_learn.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(_on_learn_selected)


func _on_forget_selected(card: Card) -> void:
	forget_card = card
	
	forget_slot.card = card
	forget_slot.set_card(card)
	await forget_slot.set_char_stats(char_stats)
	forget_card_name.text = card.name
	forget_slot.visuals._update_visuals()
	Utils.print_resource(forget_slot.card)
	forget_slot.modulate = Color(1,1,1,1)
	forget_slot_selected = true
	_update_confirm_button()


func _on_learn_selected(card: Card) -> void:
	learn_card = card
	
	learn_slot.card = card
	learn_slot.set_card(card)
	await learn_slot.set_char_stats(char_stats)
	learn_card_name.text = card.name
	learn_slot.visuals._update_visuals()
	Utils.print_resource(learn_slot.card)
	learn_slot.modulate = Color(1,1,1,1)
	learn_slot_selected = true
	_update_confirm_button()


func _on_confirm() -> void:
	var replacements: Array[Card] = []
	
	# Find all matching cards to remove
	for card in player_deck.cards:
		if card.id == forget_card.id and card.pkmn_owner_uid == pokemon.uid:
			replacements.append(card)

	# Remove matching cards
	for old_card in replacements:
		player_deck.cards.erase(old_card)

	# Replace with same number of learn_card copies
	for _i in replacements:
		print("======LEARN CARD BEFORE DUPLICATION========")
		Utils.print_resource(learn_card)
		var new_card = learn_card.duplicate(true)
		var move_data = MoveData.moves.get(learn_card.id)
		if move_data and new_card.has_method("setup_from_data"):
			new_card.setup_from_data(move_data)
		new_card.pkmn_owner_uid = pokemon.uid
		new_card.pkmn_owner_name = pokemon.species_id
		new_card.pkmn_icon = pokemon.icon
		print("======LEARN CARD AFTER DUPLICATION========")
		Utils.print_resource(new_card)
		new_card.pkmn_owner_uid = pokemon.uid  # ✅ Make sure ownership is preserved
		player_deck.cards.append(new_card)
	queue_free()


func _on_skip() -> void:
	queue_free()


func _update_confirm_button() -> void:
	confirm_button.disabled = forget_slot_selected == false or learn_slot_selected == false


func _clear_rewards() -> void:
	for card: Node in cards_to_forget.get_children():
		card.queue_free()
	for card: Node in cards_to_learn.get_children():
		card.queue_free()
	
	
	forget_slot_selected = false
	learn_slot_selected = false
