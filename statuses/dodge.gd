class_name DodgeStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	target.status_handler.block_gain_disabled = true
	status_applied.emit(self)
