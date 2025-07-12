class_name CardDetailOverlay
extends Control

const CARD_SUPER_DETAIL_UI := preload("res://scenes/ui/card_super_detail_ui.tscn")
const STATUS_TOOLTIP_SCENE := preload("res://scenes/ui/status_tooltip.tscn")
const OPEN_SOUND := preload("res://art/sounds/sfx/menu_open.wav")

@export var background_color: Color = Color("000000b0")

@onready var background: ColorRect = $Background
@onready var tooltip_card: CenterContainer = %TooltipCard
@onready var card_description: RichTextLabel = %CardDescription
@onready var card_name: Label = %CardName
@onready var inflicts: RichTextLabel = %Inflicts
@onready var status_box: VBoxContainer = %StatusBox
@onready var pokemon_name: RichTextLabel = %Pokemon
@onready var button: Button = %Button
@onready var v_box_container: VBoxContainer = %VBoxContainer


func _ready() -> void:
	for card: CardSuperDetailUI in tooltip_card.get_children():
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
	var new_card := CARD_SUPER_DETAIL_UI.instantiate() as CardSuperDetailUI
	tooltip_card.add_child(new_card)
	new_card.card = card
	new_card.tooltip_requested.connect(hide_tooltip.unbind(1))
	
	card_description.text = card.get_default_tooltip()
	card_name.text = card.name
	pokemon_name.text = "[color=goldenrod]%s[/color]" % card.pkmn_owner_name.capitalize()
	
	
	# Show statuses if available
	if card.status_effects.size() > 0:
		var seen_ids := {}
		for status in card.status_effects:
			if status.id in seen_ids:
				continue
			seen_ids[status.id] = true
			var tooltip := STATUS_TOOLTIP_SCENE.instantiate() as StatusTooltip
			tooltip.status = status
			status_box.add_child(tooltip)

	show()


func hide_tooltip() -> void:
	if not visible:
		return
	#SFXPlayer.play(OPEN_SOUND, true)
	for card: CardSuperDetailUI in tooltip_card.get_children():
		card.queue_free()
	hide()

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		hide_tooltip()
