class_name Cleanse
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	target.status_handler.remove_all_debuffs()
	status_applied.emit(self)
