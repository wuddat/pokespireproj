extends Node

var pokedex = {}
func _ready():
	var file = FileAccess.open("res://data/pokedex.json",FileAccess.READ)
	pokedex = JSON.parse_string(file.get_as_text())["pokemon"]
	var text = file.get_as_text()

	var parsed = JSON.parse_string(text)

	if parsed.has("pokemon"):
		pokedex = parsed["pokemon"]
		for key in pokedex.keys():
			print("Pokedex Load Successful ID:", key, "| Data:", pokedex[key])
	else:
		push_error("Missing 'pokemon' key in pokedex.json")

func get_pokemon_data(species_id: String) -> Dictionary:
	return pokedex.get(species_id, {})
