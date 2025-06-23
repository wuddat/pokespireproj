class_name PlatedStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	

	var block_effect:= BlockEffect.new()
	block_effect.amount = duration
	block_effect.sound = preload("res://art/block.ogg")
	
	block_effect.execute([target])
	status_applied.emit(self)
