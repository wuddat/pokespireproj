class_name MapGenerator
extends Node

const X_DIST := 60
const Y_DIST := 50
const PLACEMENT_RANDOMNESS := 5
const FLOORS := 15
const MAP_WIDTH := 7
const PATHS := 6
const MONSTEER_ROOM_WEIGHT := 10.0
const SHOP_ROOM_WEIGHT := 2.5
const POKECENTER_ROOM_WEIGHT := 4

var random_room_type_weights = {
	Room.Type.MONSTER: 0.0,
	Room.Type.POKECENTER: 0.0,
	Room.Type.SHOP: 0.0,
}
var random_room_type_total_weight := 0
var map_data: Array[Array]


func _ready() -> void:
	generate_map()


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	
	for j in starting_points:
		var current_j := j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)
	
	return []


func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []
	
	for i in FLOORS:
		var adjacent_rooms: Array[Room] = []
		
		for j in MAP_WIDTH:
			var current_room := Room.new()
			var offset := Vector2(randf(), randf()) * PLACEMENT_RANDOMNESS
			current_room.position = Vector2(j * X_DIST, i * -Y_DIST) + offset
			current_room.row = i
			current_room.column = j
			current_room.next_rooms = []
			
			#BOSS ALWAYS TOP
			if i == FLOORS - 1:
				current_room.position.y = (i + 1) * -Y_DIST
				
			adjacent_rooms.append(current_room)
			
		result.append(adjacent_rooms)
		
	return result


func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int]
	var unique_points: int = 0
	
	while unique_points <2:
		unique_points = 0
		y_coordinates = []
		
		for i in PATHS:
			var starting_point := randi_range(0, MAP_WIDTH - 1)
			if not y_coordinates.has(starting_point):
				unique_points += 1
			
			y_coordinates.append(starting_point)
			
	return y_coordinates


func _setup_connection(i: int, j: int) -> int:
	return 0
