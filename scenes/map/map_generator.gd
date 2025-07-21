#map_generator.gd
class_name MapGenerator
extends Node
# BE WARNED, ALL YE WHO ENTER HERE...
const X_DIST := 64
const Y_DIST := 96
const PLACEMENT_RANDOMNESS := 0
const FLOORS := 15
const MAP_WIDTH := 7
const PATHS := 6
const MONSTER_ROOM_WEIGHT := 10.0
const EVENT_ROOM_WEIGHT := 6.0
const SHOP_ROOM_WEIGHT := 2.5
const POKECENTER_ROOM_WEIGHT := 2.5
const TRAINER_ROOM_WEIGHT := 3

@export var battle_stats_pool: BattleStatsPool

var random_room_type_weights = {
	Room.Type.MONSTER: 0.0,
	Room.Type.POKECENTER: 0.0,
	Room.Type.SHOP: 0.0,
	Room.Type.EVENT: 0.0,
	Room.Type.TRAINER: 0.0,
}
var random_room_type_total_weight := 0
var map_data: Array[Array]


#func _ready() -> void:
	#generate_map()


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	
	for j in starting_points:
		var current_j := j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)
			
	battle_stats_pool.setup()
	
	_setup_boss_room()
	_setup_random_room_weights()
	_setup_room_types()
		
	return map_data


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
	var next_room: Room
	var current_room := map_data[i][j] as Room
	
	while not next_room or _would_cross_existing_path(i, j, next_room):
		var random_j := clampi(randi_range(j - 1, j + 1), 0, MAP_WIDTH - 1) #dont escape the array
		next_room = map_data [i+1][random_j]
		
	current_room.next_rooms.append(next_room)
	
	return next_room.column


func _would_cross_existing_path(i: int, j: int, room: Room) -> bool:
	var left_of_node: Room
	var right_of_node: Room
	
	#if j==0, theres no node to the left
	if j > 0:
		left_of_node = map_data[i][j - 1]
	#if j==mapwidth -1 no node to the right, duh
	if j < MAP_WIDTH - 1:
		right_of_node = map_data[i][j + 1]
	
	#cant cross path right if right node goes left
	if right_of_node and room.column > j:
		for next_room: Room in right_of_node.next_rooms:
			if next_room.column < room.column:
				return true
	
	#cant cross left path if left node goes right (trust it fam it makes sense)
	if left_of_node and room.column < j:
		for next_room: Room in left_of_node.next_rooms:
			if next_room.column > room.column:
				return true
	
	return false
		

func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH * 0.5)
	var boss_room := map_data[FLOORS - 1][middle] as Room
	
	for j in MAP_WIDTH:
		var current_room = map_data[FLOORS - 2][j] as Room
		if current_room.next_rooms:
			current_room.next_rooms = [] as Array[Room]
			current_room.next_rooms.append(boss_room)
	
	boss_room.type = Room.Type.BOSS
	boss_room.battle_stats = battle_stats_pool.get_random_battle_for_tier(2)


func _setup_random_room_weights() -> void:
	random_room_type_weights[Room.Type.MONSTER] = MONSTER_ROOM_WEIGHT
	random_room_type_weights[Room.Type.POKECENTER] = MONSTER_ROOM_WEIGHT + POKECENTER_ROOM_WEIGHT
	random_room_type_weights[Room.Type.SHOP] = MONSTER_ROOM_WEIGHT + POKECENTER_ROOM_WEIGHT + SHOP_ROOM_WEIGHT
	random_room_type_weights[Room.Type.EVENT] = MONSTER_ROOM_WEIGHT+ POKECENTER_ROOM_WEIGHT + SHOP_ROOM_WEIGHT + EVENT_ROOM_WEIGHT
	random_room_type_weights[Room.Type.TRAINER] = MONSTER_ROOM_WEIGHT+ POKECENTER_ROOM_WEIGHT + SHOP_ROOM_WEIGHT + EVENT_ROOM_WEIGHT + TRAINER_ROOM_WEIGHT
	random_room_type_total_weight = random_room_type_weights[Room.Type.TRAINER]

#TESTING = edit this room.type to match the room you want to test!
func _setup_room_types() -> void:
	#firstfloor is always battle
	for room: Room in map_data[0]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.MONSTER
			room.tier = 0
			room.battle_stats = battle_stats_pool.get_wild_battle_for_tier(0)
			#room.battle_stats = battle_stats_pool.get_trainer_battle_for_tier(0)
			#room.battle_stats = battle_stats_pool.get_boss_battle_for_tier(2)

	
	for floor_index in [2, 7]:  # 3rd and 8th floors (0-based index)
		for room: Room in map_data[floor_index]:
			if room.next_rooms.size() > 0:
				room.type = Room.Type.TRAINER
				room.tier = 0
				room.battle_stats = battle_stats_pool.get_trainer_battle_for_tier(room.tier)
	
		
	#9th floor is always treasure
	for room: Room in map_data[floori(FLOORS/2)]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.TREASURE
	

	
	#last floor before boss is always pokecenter
	for room: Room in map_data[FLOORS - 2]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.POKECENTER
	#other rooms
	for current_floor in map_data:
		for room: Room in current_floor:
			for next_room: Room in room.next_rooms:
				if next_room.type == Room.Type.NOT_ASSIGNED:
					_set_room_randomly(next_room)


func _set_room_randomly(room_to_set: Room) -> void:
	var pokecenter_below_4 := true
	var consecutive_pokecenter := true
	var consecutive_shop := true
	var pokecenter_before_boss := true
	
	var type_candidate: Room.Type
	
	while pokecenter_below_4 or consecutive_pokecenter or consecutive_shop or pokecenter_before_boss:
		type_candidate = _get_random_room_type_by_weight()
		
		var is_pokecenter :=  type_candidate == Room.Type.POKECENTER
		var has_pokecenter_parent := _room_has_parent_of_type(room_to_set, Room.Type.POKECENTER)
		var is_shop := type_candidate == Room.Type.SHOP
		var has_shop_parent := _room_has_parent_of_type(room_to_set, Room.Type.SHOP)
		
		pokecenter_below_4 = is_pokecenter and room_to_set.row < 3
		consecutive_pokecenter = is_pokecenter and has_pokecenter_parent
		consecutive_shop = is_shop and has_shop_parent
		pokecenter_before_boss = is_pokecenter and room_to_set.row == 12
	
	room_to_set.type = type_candidate
	
	if type_candidate == Room.Type.MONSTER:
		var tier_for_monster_rooms := 0
		
		if room_to_set.row > 5:
			tier_for_monster_rooms = 1
		
		room_to_set.tier = tier_for_monster_rooms  
		room_to_set.battle_stats = battle_stats_pool.get_wild_battle_for_tier(tier_for_monster_rooms)
	
	if type_candidate == Room.Type.TRAINER:
		var tier_for_trainer_rooms: int = 0
		
		if room_to_set.row > 5:
			tier_for_trainer_rooms = 1
		
		room_to_set.tier = tier_for_trainer_rooms
		room_to_set.battle_stats = battle_stats_pool.get_trainer_battle_for_tier(tier_for_trainer_rooms)
	
func _room_has_parent_of_type(room: Room, type: Room.Type) -> bool:
	var parents: Array[Room] = []
	#left parent
	if room.column > 0 and room.row > 0:
		var possible_parent := map_data[room.row - 1][room.column - 1] as Room
		if possible_parent.next_rooms.has(room):
			parents.append(possible_parent)
	#parent below
	if room.row > 0:
		var possible_parent := map_data[room.row - 1][room.column] as Room
		if possible_parent.next_rooms.has(room):
			parents.append(possible_parent)
	#right parent
	if room.column < MAP_WIDTH - 1 and room.row > 0:
		var possible_parent := map_data[room.row - 1][room.column + 1] as Room
		if possible_parent.next_rooms.has(room):
			parents.append(possible_parent)
	
	for parent: Room in parents:
		if parent.type == type:
			return true
			
	return false


func _get_random_room_type_by_weight() -> Room.Type:
	var roll := randf_range(0.0, random_room_type_total_weight)
	
	for type: Room.Type in random_room_type_weights:
		if random_room_type_weights[type] > roll:
			return type
			
	return Room.Type.MONSTER
