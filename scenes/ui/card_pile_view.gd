class_name CardPileView
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")
const CARD_HOVER_DETAIL_UI = preload("res://scenes/card_ui/card_hover_detail_ui.tscn")
const PKMN_CARD_DISPLAYER := preload("res://scenes/ui/pkmn_card_displayer.tscn")
const OPEN_SOUND := preload("res://art/sounds/sfx/menu_open.wav")

@export var card_pile: CardPile
@export var char_stats: CharacterStats

@onready var title: Label = %Title
@onready var cards: GridContainer = %Cards
@onready var card_detail_overlay: CardDetailOverlay = %CardDetailOverlay
@onready var backbtn: Button = %BackButton
@onready var scroll_container: VBoxContainer = %VBoxContainer
@onready var canvas_layer: CanvasLayer = $CanvasLayer


func _ready() -> void:
	backbtn.pressed.connect(_on_back_pressed)
	
	for card: Node in cards.get_children():
		card.queue_free()
	
	card_detail_overlay.hide_tooltip()
	canvas_layer.hide()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_detail_overlay.visible:
			card_detail_overlay.hide_tooltip()
		else:
			SFXPlayer.play(OPEN_SOUND, true)
			hide()


func show_current_view(new_title: String, deck_view: bool = false, randomized: bool = false) -> void:
	SFXPlayer.play(OPEN_SOUND)
	if deck_view:
		scroll_container.show()
		canvas_layer.hide()
		for pokemon: Node in scroll_container.get_children():
			pokemon.queue_free()
		for  pkmn in char_stats.current_party:
			var pkmn_display := PKMN_CARD_DISPLAYER.instantiate() as PkmnCardDisplayer
			scroll_container.add_child(pkmn_display)
			var matching_cards := card_pile.cards.filter(func(c): return c.pkmn_owner_uid == pkmn.uid)
			pkmn_display.pkmn = pkmn
			pkmn_display.char_stats = char_stats
			pkmn_display.card_detail_overlay = card_detail_overlay
			pkmn_display.update_visuals()
			
			for card in matching_cards:
				var card_ui := CARD_MENU_UI_SCENE.instantiate()
				card_ui.card = card
				card_ui.is_floatable = true
				card_ui.set_char_stats(char_stats)
				card_ui.tooltip_requested.connect(card_detail_overlay.show_tooltip)
				pkmn_display.add_card(card_ui)
			
		cards.hide()
	if deck_view == false:
		cards.show()
		canvas_layer.show()
		scroll_container.hide()
		
		
	for card: Node in cards.get_children():
		card.queue_free()
		
	card_detail_overlay.hide_tooltip()
	title.text = new_title
	_update_view.call_deferred(randomized)



func _update_view(randomized: bool) -> void:
	if not card_pile:
		return
	
	var all_cards := card_pile.cards.duplicate()
	if randomized:
		all_cards.shuffle()
	
	for card: Card in all_cards:
		var new_card := CARD_HOVER_DETAIL_UI.instantiate() as CardHoverDetailUI
		cards.add_child(new_card)
		new_card.card = card
		new_card.set_char_stats(char_stats)
		new_card.tooltip_requested.connect(card_detail_overlay.show_tooltip)
	show()
	canvas_layer.show()


func _on_back_pressed() -> void:
	SFXPlayer.play(OPEN_SOUND, true)
	for card: Node in cards.get_children():
		card.queue_free()
	hide()
