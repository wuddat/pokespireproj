class_name CardMenuUI
extends CenterContainer

signal tooltip_requested(card: Card)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_style.tres")
const HOVER_STYLEBOX := preload("res://scenes/card_ui/card_hover_style.tres")
const HOVER_OFFSET := -10.0
const HOVER_Z_INDEX := 100
const BASE_Z_INDEX := 0

@export var card: Card : set = set_card
@onready var visuals: CardVisuals = $Visuals
@onready var tween := create_tween()

func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)


func _on_visuals_mouse_entered() -> void:
		visuals.panel.set("theme_override_styles/panel", HOVER_STYLEBOX)
		set_z_index(HOVER_Z_INDEX)
		
		tween.kill()  # stop any current tween
		tween = create_tween()
		tween.tween_property(self, "position:y", HOVER_OFFSET, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_visuals_mouse_exited() -> void:
		visuals.panel.set("theme_override_styles/panel", BASE_STYLEBOX)
		set_z_index(BASE_Z_INDEX)
		
		tween.kill()
		tween = create_tween()
		tween.tween_property(self, "position:y", 0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	
	card = value
	visuals.card = card

func set_char_stats(value: CharacterStats) -> void:
	if not is_node_ready():
		await ready
	if visuals:
		visuals.char_stats = value
