#map_room.gd
class_name MapRoom
extends Area2D

signal selected(room: Room)

const ICONS:={
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://art/pokeball.png"), Vector2.ONE],
	Room.Type.TREASURE: [preload("res://art/tile_0089.png"), Vector2(1.25, 1.25)],
	Room.Type.POKECENTER:[preload("res://art/sprites/building/pokecenter.png"), Vector2(0.4, 0.4)],
	Room.Type.SHOP: [preload("res://art/sprites/building/mart.png"), Vector2(0.4, 0.4)],
	Room.Type.BOSS: [preload("res://art/sprites/spritesheets/mewtwo_mech_sprite.png"), Vector2(0.6, 0.6)],
	Room.Type.EVENT: [preload("res://art/statuseffects/confused-effect.png"), Vector2(.8, .8)],
	Room.Type.TRAINER: [preload("res://art/sprites/items/ball/premier.png"), Vector2.ONE],
	Room.Type.LEGENDARY: [preload("res://art/sprites/items/ball/luxury.png"), Vector2.ONE],
}

@export var music = preload("res://art/sounds/sfx/ui_window_open.wav")

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false: set = set_available
var room: Room : set = set_room


func _ready() -> void:
	line_2d.visible = false
	MusicPlayer.stop()


func set_available(new_value: bool) -> void:
	available = new_value
	
	if available:
		line_2d.visible = true
		animation_player.play("highlight")
		if room.type == Room.Type.BOSS:
			animation_player.play("hover")
	elif not room.selected:
		animation_player.stop()
		line_2d.visible = false
		sprite_2d.modulate = Color(1,1,1,0.7)


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = RNG.instance.randi_range(-10, 10)
	sprite_2d.scale = ICONS[room.type][1]
	if room.type == Room.Type.MONSTER:
		sprite_2d.texture = _get_monster_icon(room.tier)
	if room.type == Room.Type.TRAINER:
		sprite_2d.texture = _get_trainer_icon(room.battle_stats.trainer_type)
	else:
		sprite_2d.texture = ICONS[room.type][0]
	if room.type == Room.Type.BOSS:
			animation_player.play("hover")
	


func show_selected() -> void:
	line_2d.modulate = Color.RED


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return
	
	room.selected = true
	animation_player.play("select")
	if room.type == Room.Type.BOSS:
			animation_player.play("boss_begin")
	MusicPlayer.play(music, true)


func _get_monster_icon(tier: int) -> Texture:
	match tier:
		0: return preload("res://art/sprites/items/ball/poke.png")
		1: return preload("res://art/sprites/items/ball/great.png")
		2: return preload("res://art/sprites/items/ball/ultra.png")
		_: return preload("res://art/sprites/items/ball/poke.png")

func _get_trainer_icon(trainer: String) -> Texture:
	match trainer:
		"Aroma Lady": return preload("res://art/trainer/icons/aromalady.png")
		"Battle Girl": return preload("res://art/trainer/icons/battlegirl.png")
		"Biker": return preload("res://art/trainer/icons/biker.png")
		"Bird Keeper": return preload("res://art/trainer/icons/birdkeeper.png")
		"Black Belt": return preload("res://art/trainer/icons/blackbelt.png")
		"Bug Catcher": return preload("res://art/trainer/icons/bugcatcher.png")
		"Engineer": return preload("res://art/trainer/icons/engineer.png")
		"Fisher": return preload("res://art/trainer/icons/fisher.png")
		"Hiker": return preload("res://art/trainer/icons/hiker.png")
		"Psychic": return preload("res://art/trainer/icons/psychic.png")
		"Youngster": return preload("res://art/trainer/icons/youngster.png")
		_: return preload("res://art/sprites/items/ball/premier.png")

#called by animatioplayer when 'select' animation finishes
func _on_map_room_selected() -> void:
	selected.emit(room)
