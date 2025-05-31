class_name CardVisuals
extends Control

@export var card: Card: set = set_card

@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity
@onready var effect: Label = $Effect


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	
	card = value
	#print("Card is: ", card)
	#print("Card cost is: ", card.cost)
	cost.text = str(card.cost)
	effect.text = str(card.power)
	effect.modulate = Card.TYPE_COLORS[card.type]
	icon.texture = card.icon
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
	panel.modulate = Card.RARITY_COLORS[card.rarity]
