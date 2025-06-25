class_name Cleanse
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	target.status_handler.clear_all_statuses()
	target.status_handler.remove_status("cleanse")
