class_name CardVisuals
extends Control

@export var card: Card: set = set_card
@export var char_stats: CharacterStats

@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity
@onready var effect: Label = $Effect
@onready var owner_icon: TextureRect = $OwnerIcon

var card_set := false
var stats_set := false

func _ready():
	await get_tree().process_frame
	_update_visuals()


func set_card(value: Card) -> void:
	card = value
	card_set = true
	_try_update_visuals()

func set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	stats_set = true
	_try_update_visuals()

func _try_update_visuals() -> void:
	if card_set and stats_set:
		await get_tree().process_frame  # Optional: ensures all signals/events are flushed
		_update_visuals()


func _update_visuals() -> void:
	if not is_instance_valid(card):
		return


	cost.text = str(card.cost)
	effect.text = str(card.power)
	effect.modulate = Card.TYPE_COLORS[card.type]
	icon.texture = card.icon
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
	panel.modulate = Card.RARITY_COLORS[card.rarity]

	if card.pkmn_icon:
		owner_icon.texture = card.pkmn_icon
		owner_icon.visible = true
	else:
		owner_icon.visible = false


func get_owner_pokemon(uid: String) -> PokemonStats:
	if char_stats == null:
		return null
	var party_members = char_stats.get_all_party_members()
	for pkmn: PokemonStats in party_members:
		if pkmn.uid == uid:
			return pkmn
	return null
