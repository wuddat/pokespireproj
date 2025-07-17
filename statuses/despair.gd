class_name DespairStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	print("Despair status initialized on: %s" % target)
	if target.has_method("show_combat_text"):
		target.show_combat_text("DESPAIR", Color.DIM_GRAY)
	

func apply_status(target: Node) -> void:
	print("Despair status applied to %s" % target)
	print("Target will be unable BLOCK")
	
	status_applied.emit(self)
