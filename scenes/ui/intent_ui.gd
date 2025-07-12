class_name IntentUI
extends Control

const SLEEP_ICON := preload("res://art/statuseffects/sleep.png")
const CONFUSED_ICON := preload("res://art/statuseffects/confused-effect.png")

@onready var hoverable_tooltip: Control = $HoverableTooltip
@onready var icon: TextureRect = %Icon
@onready var icon_2: Sprite2D = %Icon2
@onready var aoe_icon: Sprite2D = %Icon3
@onready var label: Label = %Label
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var type_icon: TextureRect = %TypeIcon
@onready var target: TextureRect = %Target
@onready var panel: PanelContainer = %Panel
@onready var panel_contents: HBoxContainer = %HBoxContainer2
@onready var arrow: Sprite2D = %arrow
@onready var particles: GPUParticles2D = %Particles
@onready var swirl: TextureRect = %swirl
@onready var unit_status_indicator: UnitStatusIndicator = %UnitStatusIndicator
@export var parent: Enemy

@export var status_handler: StatusHandler




var spin_tween: Tween

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

var hover = "hover"


func _ready() -> void:
	if not is_node_ready():
		await ready
	var hover_length = animation_player.get_animation(hover).length
	var random_start = randf_range(0, hover_length)
	
	animation_player.play(hover)
	animation_player.seek(random_start, true)
	aoe_icon.hide()
	start_spinning()


func update_intent(action: EnemyAction) -> void:
	if not action.intent:
		hide()
		return
	aoe_icon.hide()
	panel.visible = true
	icon.texture = action.intent.icon
	icon.visible = icon.texture != null
	label.text = str(action.intent.current_text)
	label.visible = action.intent.current_text != " "
	target.texture = action.intent.target
	target.visible = target.texture != null
	target.scale = Vector2(1,1)
	particles.emitting = action.intent.particles_on
	#particles.process_material.color = Color(1,1,1,1) #TODO can change particle color maybe by type?
	if particles.emitting:
		swirl.visible = true
	else:
		swirl.visible = false
	if action.intent.icon:
		icon_2.texture = action.intent.icon
		animation_player.play("fade_in")
		await animation_player.animation_finished
		var hover_length = animation_player.get_animation(hover).length
		var random_start = randf_range(0, hover_length)
		animation_player.play("hover")
		animation_player.seek(random_start, true)
	else:
		icon_2.hide()
	if action.intent.targets_all:
		aoe_icon.show()
	var type := action.intent.damage_type.to_lower()
	if TYPE_ICON_INDEX.has(type):
		var index = TYPE_ICON_INDEX[type]
		var col = index % ICONS_PER_ROW
		var row = index / ICONS_PER_ROW
		var region_x = ICON_START.x + col * ICON_SPACING.x
		var region_y = ICON_START.y + row * ICON_SPACING.y
		var region = Rect2(region_x, region_y, ICON_SIZE.x, ICON_SIZE.y)
		
		var original_atlas := type_icon.texture as AtlasTexture
		if original_atlas:
			var new_atlas := AtlasTexture.new()
			new_atlas.atlas = original_atlas.atlas
			new_atlas.region = region
			new_atlas.filter_clip = original_atlas.filter_clip
			type_icon.texture = new_atlas
			type_icon.visible = true
		else:
			type_icon.visible = false
	else:
		type_icon.visible = false
		
	if parent.is_asleep:
		hide()
		return
		
	if parent.is_confused:
		hide()
		return
	else:
		show()


func start_spinning() -> void:
	var spin_size := swirl.size
	swirl.pivot_offset = spin_size / 2
	if spin_tween:
		spin_tween.kill()
	spin_tween = create_tween()
	spin_tween.set_loops()
	spin_tween.tween_property(swirl, "rotation_degrees", 360, 2.0).as_relative()


func get_tooltip_data() -> Dictionary:
	var intent_description: String = ""
	if aoe_icon.visible:
			intent_description = "Targets [color=red]ALL[/color] to"
	else: intent_description = "Intends to"
	if parent.current_action.intent_type == "Attack":
		intent_description = intent_description + " [color=red]ATTACK[/color] for [color=red]%s[/color]" % label.text
		if parent.current_action.status_effects and parent.current_action.status_effects.size() > 0:
			intent_description = intent_description + " and [color=palegreen]INFLICT[/color] a [color=palegreen]STATUS[/color]!"
		else:
			intent_description = intent_description + "!"
	if parent.current_action.intent_type == "Block":
		intent_description = intent_description + " [color=royalblue]BLOCK[/color] for [color=royalblue]%s[/color]" % parent.current_action.block
		if parent.current_action.status_effects and parent.current_action.status_effects.size() > 0:
			intent_description = intent_description + " and [color=palegreen]INFLICT[/color] a [color=palegreen]STATUS[/color]!"
		else:
			intent_description = intent_description + "!"
	if parent.current_action.intent_type == "Status":
		intent_description = intent_description + " [color=palegreen]INFLICT[/color] a [color=palegreen]STATUS[/color]!"
	return {
		"header": "[color=tan]%s[/color]:" % parent.stats.species_id.capitalize(),
		"description": intent_description
	}
