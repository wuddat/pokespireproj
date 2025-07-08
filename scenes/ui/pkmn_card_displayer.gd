class_name PkmnCardDisplayer
extends HBoxContainer

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")

@export var pkmn: PokemonStats
@export var char_stats: CharacterStats
@export var card_detail_overlay: CardDetailOverlay
@export var char_deck: CardPile
@onready var pkmn_texture: TextureRect = %PkmnTexture
@onready var pkmn_name: Label = %PkmnName
@onready var cards: GridContainer = %Cards


func _ready() -> void:
	clear_cards()
	

func update_visuals() -> void:
	pkmn_texture.texture = pkmn.art
	pkmn_name.text = pkmn.species_id.capitalize()


func add_card(card_ui: CardMenuUI) -> void:
	cards.add_child(card_ui)


func clear_cards() -> void:
	for child in cards.get_children():
		child.queue_free()
