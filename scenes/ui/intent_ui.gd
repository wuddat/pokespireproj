class_name IntentUI
extends Control


@onready var icon: TextureRect = $HBoxContainer2/HBoxContainer/Icon
@onready var label: Label = $HBoxContainer2/HBoxContainer/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var type_icon: Sprite2D = $HBoxContainer2/TypeIcon
@onready var target: Sprite2D = $Target


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
	var hover = "hover"
	var hover_length = animation_player.get_animation(hover).length
	var random_start = randf_range(0, hover_length)
	
	animation_player.play(hover)
	animation_player.seek(random_start, true)


func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return
	
	#print("🧠 IntentUI.update_intent called with:", intent)
	#print("📊 Text: %s | Icon: %s | Target: %s" % [intent.current_text, intent.icon, intent.target])

	icon.texture = intent.icon
	icon.visible = icon.texture != null
	label.text = str(intent.current_text)
	label.visible = intent.current_text.length() > 0
	target.texture = intent.target
	target.visible = target.texture != null
	
	var type := intent.damage_type.to_lower()
	if TYPE_ICON_INDEX.has(type):
		var index = TYPE_ICON_INDEX[type]
		var col = index % ICONS_PER_ROW
		var row = index / ICONS_PER_ROW
		var region_x = ICON_START.x + col * ICON_SPACING.x
		var region_y = ICON_START.y + row * ICON_SPACING.y
		type_icon.visible = true
		type_icon.region_rect = Rect2(region_x, region_y, ICON_SIZE.x, ICON_SIZE.y)
	else:
		type_icon.visible = false
	show()

	
