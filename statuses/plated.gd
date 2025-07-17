class_name PlatedStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	

	var block_effect:= BlockEffect.new()
	block_effect.amount = duration
	block_effect.sound = preload("res://art/block.ogg")
	
	block_effect.execute([target])
	
	if target.has_method("show_combat_text"):
		target.show_combat_text("BLOCK", Color.BLUE)
	
	status_applied.emit(self)
