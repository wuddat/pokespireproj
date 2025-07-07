#card_super_detail.gd
class_name CardSuperDetail
extends Control

signal tooltip_requested(card: Card)

@export var card: Card: set = set_card
@export var char_stats: CharacterStats
@onready var tween := create_tween()

@onready var panel: PanelContainer = %Panel
@onready var pkmn_border: Panel = %pkmn_border
@onready var descr_border: PanelContainer = %descr_border
@onready var card_effects: HBoxContainer = %CardEffects
@onready var rarity: TextureRect = %Rarity
@onready var cost: Label = %Cost
@onready var owner_icon: TextureRect = %OwnerIcon
@onready var type: Sprite2D = %Type
@onready var card_name: RichTextLabel = %CardName
@onready var target: RichTextLabel = %Target
@onready var dmg_icon: TextureRect = %DmgIcon
@onready var dmg_description: RichTextLabel = %DmgDescription
@onready var status_icon: TextureRect = %StatusIcon
@onready var status_description: RichTextLabel = %StatusDescription
@onready var damage: HBoxContainer = %Damage
@onready var status: HBoxContainer = %Status
@onready var card_description: RichTextLabel = %CardDescription

var is_playable: bool


var card_set := false
var stats_set := false

const TYPE_ICON_INDEX := {
	"normal": 0,
	"grass": 1,
	"fire": 2,
	"water": 3,
	"fighting": 4,
	"electric": 5,
	"flying": 6,
	"bug": 7,
	"poison": 8,
	"ice": 9,
	"rock": 10,
	"ground": 11,
	"steel": 12,
	"psychic": 13,
	"ghost": 14,
	"dark": 15,
	"fairy": 16,
	"dragon": 17
}

const ICON_SIZE := Vector2(38, 38)
const ICON_START := Vector2(16, 16)
const ICON_SPACING := Vector2(54, 54) 
const ICONS_PER_ROW := 9

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

#TODO finish updating card super detail
func _update_visuals() -> void:
	if not is_instance_valid(card):
		return
	damage.hide()
	status.hide()
	update_type_icon(card.damage_type)
	cost.text = str(card.current_cost)
	card_name.text = card.name
	card_description.text = card.tooltip_text % card.base_power
	if card.type == Card.Type.ATTACK:
		damage.show()
	if card.target_damage_percent_hp:
		dmg_description.text = "[color=red]" + str(int(card.target_damage_percent_hp * 100)) + "%[/color]"
	else:
		dmg_description.text = "[color=red]" + str(card.power) + "[/color]"
	if card.type == Card.Type.STATUS:
		damage.hide()
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
	panel.modulate = card.get_pkmn_color()
	if card.status_effects:
		status.show()
		status_icon.texture = card.status_effects[0].icon
		var i = 0
		for status in card.status_effects:
			if status.id == card.status_effects[0].id:
				i += 1
			else:
				continue
		status_description.text = str(i)
	match card.target:
		card.Target.SELF:
			target.text = "Self"
		card.Target.SINGLE_ENEMY:
			target.text ="Enemy"
		card.Target.SINGLE_ALLY:
			target.text ="Ally"
		card.Target.ALL_ALLIES:
			target.text ="Allies"
		card.Target.ALL:
			target.text ="ALL"
		card.Target.SPLASH:
			target.text ="Splash"
		card.Target.RANDOM_ENEMY:
			target.text ="Random"

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


func update_type_icon(damage_type: String) -> void:
	var dam_type := damage_type.to_lower()
	if not TYPE_ICON_INDEX.has(dam_type):
		$Type.visible = false
		return

	var index = TYPE_ICON_INDEX[dam_type]
	var col = index % ICONS_PER_ROW
	var row = index / ICONS_PER_ROW

	var region_x = ICON_START.x + col * ICON_SPACING.x
	var region_y = ICON_START.y + row * ICON_SPACING.y
	
	$Type.visible = true
	$Type.region_rect = Rect2(region_x, region_y, ICON_SIZE.x, ICON_SIZE.y)


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)
