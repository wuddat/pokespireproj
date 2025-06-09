class_name Dexterity
extends Status

func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	
	var block_mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	assert(block_mod, "No block modifier on %s" % target)

	var dex_val := block_mod.get_value("dexterity")
	if not dex_val:
		dex_val = ModifierValue.create_new_modifier("dexterity", ModifierValue.Type.FLAT)

	dex_val.flat_value = stacks
	block_mod.add_new_value(dex_val)

	status_changed.connect(_on_status_changed.bind(block_mod))

func _on_status_changed(block_mod: Modifier) -> void:
	if stacks <= 0 and block_mod:
		block_mod.remove_value("dexterity")
