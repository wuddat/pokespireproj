class_name Paralyze
extends Status

func get_tooltip() -> String:
	if duration:
		return tooltip % duration
	else:
		return tooltip

func initialize_status(target: Node) -> void:
	print("Paralysis status initialized for %s" % target.stats.species_id.capitalize())
	duration = 3
