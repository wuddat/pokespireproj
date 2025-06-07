class_name CardDetailOverlay
extends Control

const CARD_MENU_UI_SCENE := preload("res://scenes/ui/card_menu_ui.tscn")
const STATUS_TOOLTIP_SCENE := preload("res://scenes/ui/status_tooltip.tscn")

@export var background_color: Color = Color("000000b0")

@onready var background: ColorRect = $Background
@onready var tooltip_card: CenterContainer = %TooltipCard
@onready var card_description: RichTextLabel = %CardDescription
@onready var card_name: Label = %CardName
@onready var card_owner: RichTextLabel = $VBoxContainer/HBoxContainer/VBoxContainer2/CardOwner
@onready var inflicts: RichTextLabel = %Inflicts
@onready var status_box: VBoxContainer = %StatusBox
@onready var pokemon: RichTextLabel = %Pokemon


func _ready() -> void:
	for card: CardMenuUI in tooltip_card.get_children():
		card.queue_free()
	
	background.color = background_color


func show_tooltip(card: Card) -> void:
	# Clear existing card display
	for child in tooltip_card.get_children():
		child.queue_free()
	
	# Clear previous status tooltips
	for child in status_box.get_children():
		child.queue_free()

	# Create and show the card visual
	var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	tooltip_card.add_child(new_card)
	new_card.card = card
	new_card.tooltip_requested.connect(hide_tooltip.unbind(1))
	
	card_description.text = card.get_default_tooltip()
	card_name.text = card.name
	
	
	
	# Show statuses if available
	if card.status_effects.size() > 0:
		for status in card.status_effects:
			var tooltip := STATUS_TOOLTIP_SCENE.instantiate() as StatusTooltip
			tooltip.status = status
			status_box.add_child(tooltip)

	show()


func hide_tooltip() -> void:
	if not visible:
		return
	
	for card: CardMenuUI in tooltip_card.get_children():
		card.queue_free()
	hide()

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		hide_tooltip()
