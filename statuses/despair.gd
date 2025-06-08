class_name DespairStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	target.status_handler.queue_block_nullify_once("despair")
