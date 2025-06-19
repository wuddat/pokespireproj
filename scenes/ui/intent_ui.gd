class_name IntentUI
extends Control

const SLEEP_ICON := preload("res://art/statuseffects/sleep.png")
const CONFUSED_ICON := preload("res://art/statuseffects/confused-effect.png")

@onready var icon: TextureRect = $HBoxContainer2/HBoxContainer/Icon
@onready var label: Label = $HBoxContainer2/HBoxContainer/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var type_icon: Sprite2D = $HBoxContainer2/TypeIcon
@onready var target: Sprite2D = $Target
@onready var panel: Panel = $Panel
@onready var panel_contents: HBoxContainer = $HBoxContainer2
@onready var arrow: Sprite2D = $HBoxContainer2/arrow

@export var parent: Enemy

@export var status_handler: StatusHandler


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



func _ready() -> void:
	if not is_node_ready():
		await ready
	var hover = "hover"
	var hover_length = animation_player.get_animation(hover).length
	var random_start = randf_range(0, hover_length)
	
	animation_player.play(hover)
	animation_player.seek(random_start, true)
	
	Utils.print_node(parent)


func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return
	print("parent is: ", parent)
	#print("🧠 IntentUI.update_intent called with:", intent)
	#print("📊 Text: %s | Icon: %s | Target: %s" % [intent.current_text, intent.icon, intent.target])

	panel.visible = true
	icon.texture = intent.icon
	icon.visible = icon.texture != null
	label.text = str(intent.current_text)
	label.visible = intent.current_text.length() > 0
	target.texture = intent.target
	target.visible = target.texture != null
	target.scale = Vector2(1,1)
	
	var type := intent.damage_type.to_lower()
	if TYPE_ICON_INDEX.has(type):
		var index = TYPE_ICON_INDEX[type]
		var col = index % ICONS_PER_ROW
		var row = index / ICONS_PER_ROW
		var region_x = ICON_START.x + col * ICON_SPACING.x
		var region_y = ICON_START.y + row * ICON_SPACING.y
		type_icon.region_rect = Rect2(region_x, region_y, ICON_SIZE.x, ICON_SIZE.y)
	else:
		type_icon.visible = false
	show()
	
	get_tree().create_timer(.1).timeout
	if parent.is_asleep:
		icon.texture = SLEEP_ICON
		target.texture = SLEEP_ICON
		print("intentUI set to SLEEP")
		label.text = ""
		target.visible = false
		panel.visible = false
		type_icon.visible = false
		arrow.visible = false
		return
	if parent.is_confused:
		print("intentUI set to CONFUSED")
		target.visible = true
		target.scale = Vector2(.6,.6)
		panel.visible = true
		type_icon.visible = true
		arrow.visible = true
