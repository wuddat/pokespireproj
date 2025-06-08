class_name Protected
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	target.status_handler.queue_ignore_next_damage("protected")
	status_applied.emit(self)
