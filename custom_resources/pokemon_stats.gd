class_name PokemonStats
extends Stats

#TODO update to relevant pokemon stats per JSON
@export var species_id: String
@export var move_ids: Array[String] = []
@export var type: Array[String] = []

#func create_instance() -> Resource:
	#var instance: PokemonStats = self.duplicate()
	#instance.health = max_health
	#instance.block = 0
	#return instance

#func set_health(value: int) -> void:
	#health = clampi(value, 0, max_health)
	#print("Health changed: %d" % health)
	#print(move_ids)
	#stats_changed.emit()
