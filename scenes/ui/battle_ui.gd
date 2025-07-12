class_name BattleUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats
@export var party_view: PartyView

@onready var hand: Hand = $Hand as Hand
@onready var mana_ui: ManaUI = $ManaUI as ManaUI
@onready var oom_panel: PanelContainer = %OOMPanel
@onready var end_turn_button: Button = %EndTurnButton
@onready var draw_pile_button: CardPileOpener = %DrawPileButton
@onready var discard_pile_button: CardPileOpener = %DiscardPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
const END_TURN = preload("res://art/sounds/sfx/end_turn.mp3")

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.battle_text_requested.connect(_on_battle_text_requested)
	Events.battle_text_completed.connect(_on_battle_text_completed)
	
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", false, true))
	draw_pile_button.container_name = "Draw Pile"
	discard_pile_button.container_name = "Discard Pile"
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("Discard Pile"))
	draw_pile_view.party_view = party_view
	discard_pile_view.party_view = party_view


func initialize_card_pile_ui() -> void:
	draw_pile_view.char_stats = char_stats
	discard_pile_view.char_stats = char_stats

	draw_pile_button.card_pile = char_stats.draw_pile
	draw_pile_view.card_pile = char_stats.draw_pile
	discard_pile_button.card_pile = char_stats.discard
	discard_pile_view.card_pile = char_stats.discard


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	mana_ui.char_stats = char_stats
	hand.char_stats = char_stats


func _on_player_hand_drawn() -> void:
	end_turn_button.disabled = false


func _on_end_turn_button_pressed() -> void:
	end_turn_button.disabled = true
	oom_panel.hide_oom()
	Events.player_turn_ended.emit()

func _on_battle_text_requested(_string: String) -> void:
	end_turn_button.disabled = true
	hand.disable_hand()

func _on_battle_text_completed() -> void:
	end_turn_button.disabled = false
	hand.enable_hand()
