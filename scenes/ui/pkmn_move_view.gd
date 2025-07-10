class_name PkmnMoveView
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")
const PKMN_CARD_DISPLAYER := preload("res://scenes/ui/pkmn_card_displayer.tscn")
const OPEN_SOUND := preload("res://art/sounds/sfx/menu_open.wav")

@export var card_pile: CardPile
@export var char_stats: CharacterStats
@export var selected_pkmn: PokemonStats

@onready var title: Label = %Title
@onready var card_detail_overlay: CardDetailOverlay = %CardDetailOverlay
@onready var backbtn: Button = %BackButton
@onready var scroll_container: VBoxContainer = %VBoxContainer


func _ready() -> void:
	backbtn.pressed.connect(_on_back_pressed)
	
	card_detail_overlay.hide_tooltip()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_detail_overlay.visible:
			card_detail_overlay.hide_tooltip()
		else:
			SFXPlayer.play(OPEN_SOUND, true)
			hide()


func show_current_view(new_title: String, _randomized: bool = false) -> void:
	print("📜 Showing view for:", selected_pkmn.species_id)
	SFXPlayer.play(OPEN_SOUND)
	for pokemon: Node in scroll_container.get_children():
		pokemon.queue_free()
	
	var selected_pkmn_pile: CardPile = char_stats.build_deck_from_pokemon(selected_pkmn)
	var common_pile: CardPile = CardPile.new()
	var uncommon_pile: CardPile = CardPile.new()
	var rare_pile: CardPile = CardPile.new()
	
	common_pile.cards = selected_pkmn_pile.cards.filter(
		func (card:Card) -> bool:
			return card.rarity == Card.Rarity.COMMON
	).duplicate()
	print("🟦 Common:", common_pile.cards.size())
	uncommon_pile.cards = selected_pkmn_pile.cards.filter(
		func (card:Card) -> bool:
			return card.rarity == Card.Rarity.UNCOMMON
	).duplicate()
	print("🟪 Uncommon:", uncommon_pile.cards.size())
	rare_pile.cards = selected_pkmn_pile.cards.filter(
		func (card:Card) -> bool:
			return card.rarity == Card.Rarity.RARE
	).duplicate()
	print("🟨 Rare:", rare_pile.cards.size())
	if common_pile.cards.size() > 0:
		_add_pile_section(common_pile)
		
	if uncommon_pile.cards.size() > 0:
		_add_pile_section(uncommon_pile)
	
	if rare_pile.cards.size() > 0:
		_add_pile_section(rare_pile)
		
	card_detail_overlay.hide_tooltip()

func _on_back_pressed() -> void:
	SFXPlayer.play(OPEN_SOUND, true)
	hide()


func _populate_cards(cardpile: CardPile, display: PkmnCardDisplayer) -> void:
	for card in cardpile.cards:
			var card_ui := CARD_MENU_UI_SCENE.instantiate()
			card_ui.card = card
			card_ui.is_floatable = true
			card_ui.set_char_stats(char_stats)
			card_ui.tooltip_requested.connect(card_detail_overlay.show_tooltip)
			display.add_card(card_ui)


func _add_pile_section(pile: CardPile):
	if pile.cards.is_empty(): return
	var pkmn_display := PKMN_CARD_DISPLAYER.instantiate()
	scroll_container.add_child(pkmn_display)
	pkmn_display.pkmn = selected_pkmn
	pkmn_display.char_stats = char_stats
	pkmn_display.card_detail_overlay = card_detail_overlay
	pkmn_display.update_visuals()
	_populate_cards(pile, pkmn_display)
