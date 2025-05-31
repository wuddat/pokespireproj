class_name CardPileView
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

@export var card_pile: CardPile

@onready var title: Label = %Title
@onready var cards: GridContainer = %Cards
@onready var card_detail_overlay: CardDetailOverlay = %CardDetailOverlay
@onready var backbtn: Button = %BackButton


func _ready() -> void:
	backbtn.pressed.connect(hide)
	
	for card: Node in cards.get_children():
		card.queue_free()
	
	card_detail_overlay.hide_tooltip()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_detail_overlay.visible:
			card_detail_overlay.hide_tooltip()
		else:
			hide()


func show_current_view(new_title: String, randomized: bool = false) -> void:
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
		var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		cards.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(card_detail_overlay.show_tooltip)
		
	show()
