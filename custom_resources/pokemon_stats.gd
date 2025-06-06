class_name PokemonStats
extends Stats

#TODO update to relevant pokemon stats per JSON
@export var species_id: String
@export var move_ids: Array[String] = []
@export var type: Array[String] = []
@export var draft_pool: Array[String] = []


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
	print("PKMN TYPE: ", type)
	for t in type:
		print("Checking type: ", t)
		var moves_for_type = MoveData.type_to_moves.get(t, [])
		print("Moves for type '%s': %s" % [t, moves_for_type])
		for move_id in moves_for_type:
			if not combined_moves.has(move_id):
				combined_moves.append(move_id)
	return combined_moves
