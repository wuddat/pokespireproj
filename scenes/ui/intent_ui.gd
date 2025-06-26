class_name IntentUI
extends Control

const SLEEP_ICON := preload("res://art/statuseffects/sleep.png")
const CONFUSED_ICON := preload("res://art/statuseffects/confused-effect.png")

@onready var icon_2: Sprite2D = %Icon2
@onready var icon: TextureRect = %Icon
@onready var label: Label = %Label
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var type_icon: TextureRect = %TypeIcon
@onready var target: TextureRect = %Target
@onready var panel: PanelContainer = %Panel
@onready var panel_contents: HBoxContainer = %HBoxContainer2
@onready var arrow: Sprite2D = %arrow
@onready var particles: GPUParticles2D = %Particles
@onready var swirl: TextureRect = %swirl
@export var parent: Enemy
@onready var aoe_icon: Sprite2D = %Icon3

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
	
	Utils.print_node(parent)
	start_spinning()


func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return
	aoe_icon.hide()
	panel.visible = true
	icon.texture = intent.icon
	icon.visible = icon.texture != null
	label.text = str(intent.current_text)
	label.visible = intent.current_text != " "
	target.texture = intent.target
	target.visible = target.texture != null
	target.scale = Vector2(1,1)
	particles.emitting = intent.particles_on
	#particles.process_material.color = Color(1,1,1,1) #TODO can change particle color maybe by type?
	if particles.emitting:
		swirl.visible = true
	else:
		swirl.visible = false
	if intent.icon:
		icon_2.texture = intent.icon
		animation_player.play("fade_in")
		await animation_player.animation_finished
		var hover_length = animation_player.get_animation(hover).length
		var random_start = randf_range(0, hover_length)
		animation_player.play("hover")
		animation_player.seek(random_start, true)
	else:
		icon_2.hide()
	if intent.targets_all:
		aoe_icon.show()
	var type := intent.damage_type.to_lower()
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
	show()
	
	await get_tree().create_timer(.1).timeout
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
		
	elif parent.is_confused:
		print("intentUI set to CONFUSED")
		target.visible = true
		target.scale = Vector2(0.6,0.6)
		panel.visible = true
		type_icon.visible = true
		arrow.visible = true
	
	elif intent.targets_all:
		aoe_icon.show()
		aoe_icon.visible = true
		

func start_spinning() -> void:
	var size := swirl.size
	swirl.pivot_offset = size / 2
	if spin_tween:
		spin_tween.kill()
	spin_tween = create_tween()
	spin_tween.set_loops()
	spin_tween.tween_property(swirl, "rotation_degrees", 360, 2.0).as_relative()
