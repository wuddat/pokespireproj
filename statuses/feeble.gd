class_name FeebleStatus
extends Status

func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	var mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	var mod_val := ModifierValue.create_new_modifier("feeble", ModifierValue.Type.FLAT)
	mod_val.flat_value = -stacks
	mod.add_new_value(mod_val)
	target.status_handler.queue_remove_on_next_block("feeble")


func apply_status(target: Node) -> void:
	target.status_handler.block_penalty = stacks
	status_applied.emit(self)
