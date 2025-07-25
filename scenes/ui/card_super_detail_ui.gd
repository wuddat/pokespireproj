class_name CardSuperDetailUI
extends CenterContainer

signal tooltip_requested(card: Card)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_style.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_style.tres")
const HOVER_OFFSET := -10.0
const HOVER_Z_INDEX := 100
const BASE_Z_INDEX := 0
const CARD_FLICK_1 = preload("res://art/sounds/sfx/card_flick1.mp3")

@export var card: Card : set = set_card
@onready var tween : Tween
@onready var card_super_detail: CardSuperDetail = $CardSuperDetail

var is_floatable: bool = false
var is_hoverable: bool = true

func _on_visuals_gui_input(event: InputEvent) -> void:
	if is_hoverable:
		if event.is_action_pressed("left_mouse"):
			tooltip_requested.emit(card)


func _on_visuals_mouse_entered() -> void:
	if is_hoverable:
		SFXPlayer.pitch_play(CARD_FLICK_1)
		card_super_detail.panel.set("theme_override_styles/panel", HOVER_STYLEBOX)
		set_z_index(HOVER_Z_INDEX)
		
		if is_floatable and tween.is_running():
			tween.kill()  # stop any current tween
			tween = create_tween()
			tween.tween_property(self, "position:y", HOVER_OFFSET, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_visuals_mouse_exited() -> void:
	if is_hoverable:
		card_super_detail.panel.set("theme_override_styles/panel", BASE_STYLEBOX)
		set_z_index(BASE_Z_INDEX)
		
		if is_floatable and tween.is_running():
			tween.kill()
			tween = create_tween()
			tween.tween_property(self, "position:y", 0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	
	card = value
	card_super_detail.card = card

func set_char_stats(value: CharacterStats) -> void:
	if not is_node_ready():
		await ready
	if card_super_detail:
		card_super_detail.char_stats = value
