#card_rewards.gd
class_name CardRewards
extends ColorRect

signal card_reward_selected(card: Card)

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")
const CARD_SUPER_DETAIL = preload("res://scenes/ui/card_super_detail_ui.tscn")
const OPEN_SOUND := preload("res://art/sounds/sfx/menu_open.wav")
const PING_SOUND := preload("res://art/sounds/sfx/pc_menu_select.wav")

@export var rewards: Array[Card] : set = set_rewards

@onready var cards: HBoxContainer = %Cards
@onready var skip_button: Button = %SkipButton
@onready var card_detail_overlay: CardDetailOverlay = $CardDetailOverlay
@onready var take_button: Button = %TakeButton


var selected_card: Card


func _ready()-> void:
	_clear_rewards()
	
	take_button.reparent(card_detail_overlay.v_box_container)
	take_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	
	take_button.pressed.connect(
		func():
			card_reward_selected.emit(selected_card)
			SFXPlayer.play(PING_SOUND, true)
			queue_free()
	)
	
	skip_button.pressed.connect(
		func():
			card_reward_selected.emit(null)
			SFXPlayer.play(OPEN_SOUND, true)
			queue_free()
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		card_detail_overlay.hide_tooltip()


func _clear_rewards() -> void:
	for card: Node in cards.get_children():
		card.queue_free()
	
	card_detail_overlay.hide_tooltip()
	
	selected_card = null


func _show_tooltip(card: Card) -> void:
	
	selected_card = card
	SFXPlayer.play(PING_SOUND, true)
	card_detail_overlay.show_tooltip(card)


func set_rewards(new_cards: Array[Card]) -> void:
	rewards = new_cards
	
	if not is_node_ready():
		await ready
		
	_clear_rewards()
	for card: Card in rewards:
		var new_card := CARD_SUPER_DETAIL.instantiate()
		cards.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(_show_tooltip)
