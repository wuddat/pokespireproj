class_name Double
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	var statuses = target.status_handler.get_statuses()
	for status in statuses:
		if status.duration:
			status.duration *= 2
		if status.stacks:
			status.stacks *= 2
	target.status_handler.has_and_consume_status("double")
	status_applied.emit(self)
