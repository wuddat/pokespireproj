class_name DeckPileView
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")
const PKMN_CARD_DISPLAYER := preload("res://scenes/ui/pkmn_card_displayer.tscn")

@export var card_pile: CardPile
@export var char_stats: CharacterStats

@onready var title: Label = %Title
@onready var card_detail_overlay: CardDetailOverlay = %CardDetailOverlay
@onready var backbtn: Button = %BackButton
@onready var display_container: ScrollContainer = %DisplayContainer


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	backbtn.pressed.connect(hide)

	if not Events.added_pkmn_to_party.is_connected(_refresh_party_display):
		Events.added_pkmn_to_party.connect(_refresh_party_display)

	_refresh_party_display()
	
	card_detail_overlay.hide_tooltip()



func _refresh_party_display() -> void:
	# Clear existing display
	for child in display_container.get_children():
		child.queue_free()

	# Rebuild display
	for p in char_stats.current_party:
		var displayer := PKMN_CARD_DISPLAYER.instantiate() as PkmnCardDisplayer
		displayer.pkmn = p
		displayer.char_stats = char_stats
		displayer.card_detail_overlay = %CardDetailOverlay  # Make sure this is in your scene!
		display_container.add_child(displayer)
		displayer.pkmn_cardpile = char_stats.deck
		displayer.update_visuals()

	show()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_detail_overlay.visible:
			card_detail_overlay.hide_tooltip()
		else:
			hide()
