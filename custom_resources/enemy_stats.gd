#enemy_stats.gd
class_name EnemyStats
extends PokemonStats

@export var ai: PackedScene
var skip_turn: bool = false
var has_slept: bool = false

func load_from_pokedex(data: Dictionary) -> void:
	if data.is_empty():
		print("Tried to load stats from empty data.")
		push_warning("Tried to load stats from empty data.")
		return
	
	max_health = data.get("max_health", 10)
	art = load(data.get("sprite_path", "res://default.png"))
	icon = load(data.get("icon_path", "res://art/dottedline.png"))
	
	#clean pokedex move array so it play nice
	var raw_ids = data.get("move_ids", ["tackle"])
	var cleaned_ids: Array[String] = []
	if typeof(raw_ids) == TYPE_ARRAY:
		for id in raw_ids:
			cleaned_ids.append(str(id))
	elif typeof(raw_ids) == TYPE_STRING:
		cleaned_ids.append(raw_ids)  # It's already a string, just put it into an array
	else:
		push_warning("Unexpected move_ids format: " + str(raw_ids))

	move_ids = cleaned_ids
	
	#DEBUGVERSION
			#print("Data is: ", data)
	#max_health = data.get("max_health", 10)
	#art = load(data.get("sprite_path", "res://default.png"))
	#var raw_ids = data.get("move_ids", ["tackle"])
	#print("Raw ids: ", raw_ids)
	#var cleaned_ids: Array[String] = []
	#print("cleaned ids: ", cleaned_ids)
	#if typeof(raw_ids) == TYPE_ARRAY:
		#for id in raw_ids:
			#cleaned_ids.append(str(id))
			#print("%s appended successfully" % id)
	#elif typeof(raw_ids) == TYPE_STRING:
		#cleaned_ids.append(raw_ids)  # It's already a string, just put it into an array
		#print("%s was a string so moved it" % raw_ids)
	#else:
		#push_warning("Unexpected move_ids format: " + str(raw_ids))
	
	# Set runtime health to max_health
	health = max_health
