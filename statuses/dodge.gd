class_name DodgeStatus
extends Status

func get_tooltip() -> String:
	return tooltip % stacks

func apply_status(target: Node) -> void:
	status_applied.emit(self)
