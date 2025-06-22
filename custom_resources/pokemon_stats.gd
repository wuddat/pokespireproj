#pokemon_stats.gd
class_name PokemonStats
extends Stats

@export var species_id: String
@export var move_ids: Array[String] = []
@export var type: Array[String] = []
@export var draft_pool: Array[String] = []
@export var is_battling: bool = false
@export var leveled_up_in_battle = false

@export var evolves_to: String = ""
@export var evolution_level: int = 101
@export var current_exp: int = 0
@export var level: int = 1

func get_xp_for_next_level(lvl: int) -> int:
	return 10 + health * 1.2 * lvl

func get_evolved_species_id() -> String:
	return evolves_to

func evolve_to(new_species_id: String):
	var data := Pokedex.get_pokemon_data(new_species_id)
	if data.is_empty():
		push_error("Missing evolution data for: " + new_species_id)
		return

	species_id = new_species_id
	art = load(data.get("sprite_path", "res://art/dottedline.png"))
	icon = load(data.get("icon_path", "res://art/dottedline.png"))
	max_health += 10
	health = max_health
	move_ids = Utils.to_typed_string_array(data.get("move_ids", []))
	type = Utils.to_typed_string_array(data.get("type", []))
	evolves_to = data.get("evolves_to", "")
	evolution_level = data.get("evolution_level", 101)

func try_gain_exp_from(enemy: Enemy) -> bool:
	var gained_exp := enemy.stats.max_health * 2
	current_exp += gained_exp
	var did_level := false
	var level_threshold := get_xp_for_next_level(level)

	if current_exp >= level_threshold:
		if level != 100:
			level += 1
			max_health += level
			health += level
			did_level = true
	return did_level


static func from_enemy_stats(stats: PokemonStats) -> PokemonStats:
	var new_stats := PokemonStats.new()
	new_stats.species_id = stats.species_id
	new_stats.move_ids = stats.move_ids.duplicate()
	new_stats.max_health = stats.max_health
	new_stats.health = stats.max_health
	new_stats.art = stats.art
	new_stats.type = stats.type.duplicate()
	new_stats.icon = stats.icon
	return new_stats


func get_draft_cards_from_type() -> Array[String]:
	var combined_moves: Array[String] = []
	#print("PKMN TYPE: ", type)
	for t in type:
		#print("Checking type: ", t)
		var moves_for_type = MoveData.type_to_moves.get(t, [])
		#print("Moves for type '%s': %s" % [t, moves_for_type])
		for move_id in moves_for_type:
			if not combined_moves.has(move_id):
				combined_moves.append(move_id)
	return combined_moves
