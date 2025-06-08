class_name Dexterity
extends Status

func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	var block_gain_mod:Modifier = target.modifier_handler.get_modifier(Modifier.Type.BLOCK_GAINED)
	var mod_val := ModifierValue.create_new_modifier("dexterity", ModifierValue.Type.FLAT)
	mod_val.flat_value = stacks
	block_gain_mod.add_new_value(mod_val)

func _on_status_changed(mod: Modifier) -> void:
	mod.get_value("dexterity").flat_value = stacks
