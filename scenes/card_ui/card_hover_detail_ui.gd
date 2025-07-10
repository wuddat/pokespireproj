# card_hover_detail_ui.gd
class_name CardHoverDetailUI
extends CenterContainer

signal tooltip_requested(card: Card)

@export var card : Card : set = set_card
@onready var card_menu_ui: CardMenuUI = %CardMenuUI
@onready var card_super_detail_ui: CardSuperDetailUI = %CardSuperDetailUI
@onready var area_2d: Area2D = %Area2D
@onready var super_detail_container: CanvasLayer = %SuperDetailContainer

func _ready():
	area_2d.mouse_entered.connect(_on_area_mouse_entered)
	area_2d.mouse_exited.connect(_on_area_mouse_exited)
	card_super_detail_ui.modulate.a = 0.0
	var cmenu = card_menu_ui.get_children()
	var dmenu = card_super_detail_ui.get_children()
	for c in cmenu:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for d in dmenu:
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_area_mouse_entered() -> void:
	print("mouse entered")

	# Set initial position offset from the menu card
	var desired_pos = Vector2(card_menu_ui.global_position.x - 33, card_menu_ui.global_position.y - 43)
	card_super_detail_ui.global_position = desired_pos
	
	# Get size of the card and the size of the viewport
	var card_size = card_super_detail_ui.size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Clamp X and Y to ensure the full card stays in view
	var clamped_x = clamp(desired_pos.x, 20, viewport_size.x - card_size.x)
	var clamped_y = clamp(desired_pos.y, 20, viewport_size.y - card_size.y)

	# Apply the corrected position
	card_super_detail_ui.global_position = Vector2(clamped_x, clamped_y)

	# Toggle visibility via alpha
	card_menu_ui.modulate.a = 0.0
	card_super_detail_ui.modulate.a = 1.0
	await get_tree().process_frame
	card_super_detail_ui.show()


func _on_area_mouse_exited() -> void:
	print("mouse exited")
	card_menu_ui.modulate.a = 1.0
	card_super_detail_ui.modulate.a = 0.0
	await get_tree().process_frame
	card_super_detail_ui.hide()


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	
	card = value
	card_menu_ui.card = card
	card_super_detail_ui.card = card

func set_char_stats(value: CharacterStats) -> void:
	if not is_node_ready():
		await ready
	if card_menu_ui.visuals:
		card_menu_ui.visuals.char_stats = value
	if card_super_detail_ui.card_super_detail:
		card_super_detail_ui.card_super_detail.char_stats = value

func _on_card_super_detail_ui_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)
		card_super_detail_ui.modulate = Color (1,1,1,0)
