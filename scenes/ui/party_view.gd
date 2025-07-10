#party_view.gd
class_name PartyView
extends Control

const CARD_AMT_CONTAINER = preload("res://scenes/ui/card_amt_container.tscn")
const OPEN_SOUND := preload("res://art/sounds/sfx/menu_open.wav")
const PULSE_SHADER := preload("res://pulse.gdshader")


@onready var card_grid_container: GridContainer = %CardGridContainer
@onready var back_button: Button = %BackButton
@onready var pokemon_container: PokemonContainer = %PokemonContainer

@export var char_stats: CharacterStats

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	for child in card_grid_container.get_children():
		child.queue_free()
	hide()

func _populate_pkmn_cards(pkmn_uid: String) -> void:
	var cards = char_stats.get_party_pkmn_cards(pkmn_uid).cards
	var card_amt_map: Dictionary = {}  # key: card.id, value: CardAmountContainer
	
	pokemon_container.pkmn = char_stats.get_individual_pkmn(pkmn_uid)

	for card in cards:
		if card.id in card_amt_map:
			card_amt_map[card.id].card_amt += 1
		else:
			var new_card_amt: CardAmountContainer = CARD_AMT_CONTAINER.instantiate()
			card_grid_container.add_child(new_card_amt)
			new_card_amt.card = card
			new_card_amt.card_amt = 1
			new_card_amt.set_char_stats(char_stats)
			card_amt_map[card.id] = new_card_amt


func show_party_view(pkmn_uid: String) -> void:
	_populate_pkmn_cards(pkmn_uid)
	SFXPlayer.play(OPEN_SOUND, true)
	show()


func _on_back_pressed() -> void:
	SFXPlayer.play(OPEN_SOUND, true)
	for card: Node in card_grid_container.get_children():
		card.queue_free()
	hide()
