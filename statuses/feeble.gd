class_name FeebleStatus
extends Status

func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)
	
	if target.has_method("show_combat_text"):
		target.show_combat_text("FEEBLE", Color.DIM_GRAY)


func _on_status_changed(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	
	var block_mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	assert(block_mod, "No block modifier on %s" % target)
	
	var block_val := block_mod.get_value("feeble")
	
	if not block_val:
		block_val = ModifierValue.create_new_modifier("feeble", ModifierValue.Type.FLAT)
	
	block_val.flat_value = -stacks
	block_mod.add_new_value(block_val)
	print("Enemy has a total value of: ", block_val)
