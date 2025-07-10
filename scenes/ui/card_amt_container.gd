#card_amount_container
class_name CardAmountContainer
extends VBoxContainer

@onready var card_hover_detail_ui: CardHoverDetailUI = %CardHoverDetailUI
@onready var label: Label = %Label

@export var card_amt: int : set = _set_value
@export var card : Card : set = _set_card
var card_id: String

func _set_value(value: int) -> void:
	card_amt = value
	label.text = "X " + str(value)


func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	
	card = value
	card_hover_detail_ui.card = card


func set_char_stats(value: CharacterStats) -> void:
	if not is_node_ready():
		await ready
	if card_hover_detail_ui:
		card_hover_detail_ui.card_menu_ui.visuals.char_stats = value
	if card_hover_detail_ui.card_super_detail_ui.card_super_detail:
		card_hover_detail_ui.card_super_detail_ui.card_super_detail.char_stats = value
