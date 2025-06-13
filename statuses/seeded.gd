class_name Seeded
extends Status

@export var heal_strength := 3

func apply_status(target: Node) -> void:
	status_applied.emit(self)
