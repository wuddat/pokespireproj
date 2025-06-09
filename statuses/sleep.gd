class_name Sleep
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	if target.has_method("skip_turn"):
		target.skip_turn = true
	stacks = 0
	status_applied.emit(self)
