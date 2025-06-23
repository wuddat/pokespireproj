class_name Paralyze
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	print("Paralysis status initialized for %s" % target.stats.species_id.capitalize())
	duration = 3
