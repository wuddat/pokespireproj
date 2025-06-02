class_name MapRoom
extends Area2D

signal selected(room: Room)

const ICONS:={
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://art/pokeball.png"), Vector2.ONE],
	Room.Type.TREASURE: [preload("res://art/tile_0089.png"), Vector2(1.25, 1.25)],
	Room.Type.POKECENTER:[preload("res://art/nurse.png"), Vector2(0.5, 0.5)],
	Room.Type.SHOP: [preload("res://art/shop.png"), Vector2(1.4, 1.4)],
	Room.Type.BOSS: [preload("res://art/tile_0092.png"), Vector2(1.25, 1.25)],
}

@export var music: AudioStream

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
	elif not room.selected:
		animation_player.play("RESET")
		line_2d.visible = false
		sprite_2d.modulate = Color(1,1,1,0.7)
		


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(-10, 10)
	sprite_2d.texture = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]


func show_selected() -> void:
	line_2d.modulate = Color.RED


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return
	
	room.selected = true
	animation_player.play("select")
	MusicPlayer.play(music, true)


#called by animatioplayer when 'select' animation finishes
func _on_map_room_selected() -> void:
	selected.emit(room)
