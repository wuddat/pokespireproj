extends Node

var pokedex = {}

#var DRAFT_CARD_POOLS := {
	#"normal":["Raichu", "tackle"],
	#"fighting":["Raichu", "tackle"],
	#"flying":["Raichu", "tackle"],
	#"poison":["Raichu", "tackle"],
	#"ground":["Raichu", "tackle"],
	#"rock":["Raichu", "tackle"],
	#"bug":["Raichu", "tackle"],
	#"ghost":["Raichu", "tackle"],
	#"steel":["Raichu", "tackle"],
	#"fire":["Raichu", "tackle"],
	#"water":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#"name":["Raichu", "tackle"],
	#
#}

func _ready():
	var file = FileAccess.open("res://data/pokedex.json",FileAccess.READ)
	pokedex = JSON.parse_string(file.get_as_text())["pokemon"]
	var text = file.get_as_text()

	var parsed = JSON.parse_string(text)

	if parsed.has("pokemon"):
		pokedex = parsed["pokemon"]
		#for key in pokedex.keys():
			#print("Pokedex Load Successful ID:", key, "| Data:", pokedex[key])
	else:
		push_error("Missing 'pokemon' key in pokedex.json")

func get_pokemon_data(species_id: String) -> Dictionary:
	return pokedex.get(species_id, {})

#TODO ensure pokemon generation functions 
func create_pokemon_instance(species_id: String) -> PokemonStats:
	var data := get_pokemon_data(species_id)
	if data.is_empty():
		push_warning("No data for species: " + species_id)
		return null

	var pokemon := PokemonStats.new()
	pokemon.species_id = species_id
	pokemon.max_health = data.get("max_health", 10)
	pokemon.health = pokemon.max_health
	pokemon.art = load(data.get("sprite_path", "res://art/dottedline.png"))
	pokemon.icon = load(data.get("icon_path", "res://art/dottedline.png"))
	pokemon.uid = "pkmn_" + str(Time.get_unix_time_from_system())
	print("uid generated as: ", pokemon.uid)
	
	# WASH IT AND DRY IT BABY
	var dirty_move_ids = data.get("move_ids", [])
	var clean_move_ids = Utils.to_typed_string_array(dirty_move_ids)
	pokemon.move_ids.append_array(clean_move_ids)

	# WASH IT AND DRY IT BABY (tackles the Array instead of Array[String] error
	var dirty_types = data.get("type", [])
	var clean_types = Utils.to_typed_string_array(dirty_types)
	pokemon.type.append_array(clean_types)

	return pokemon


	# Optional: Add sprite_path or type if needed later
	# 
	# pokemon.type = data.get("type", [])  # assuming type is also an array

	# DEBUG PRINTS
	#print("Created Pokemon:", species_id)
	#print("  Max Health:", pokemon.max_health)
	#print("  Move IDs:", pokemon.move_ids)
