class_name PokemonStats
extends Stats

#TODO update to relevant pokemon stats per JSON
@export var species_id: String
@export var move_ids: Array[String] = []
@export var type: Array[String] = []


static func from_enemy_stats(stats: PokemonStats) -> PokemonStats:
	var new_stats := PokemonStats.new()
	new_stats.species_id = stats.species_id
	new_stats.move_ids = stats.move_ids.duplicate()
	new_stats.max_health = stats.max_health
	new_stats.health = stats.max_health
	new_stats.art = stats.art
	new_stats.type = stats.type.duplicate()
	return new_stats


#func set_health(value: int) -> void:
	#health = clampi(value, 0, max_health)
	#print("Health changed: %d" % health)
	#print(move_ids)
	#stats_changed.emit()
