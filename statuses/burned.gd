class_name Burned
extends Status


func get_tooltip() -> String:
	return tooltip % stacks

func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	
	var dmg_taken_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	assert(dmg_taken_modifier, "No dmg taken modifier on %s" % target)
	
	var burned_mod_val := dmg_taken_modifier.get_value("burned")
		
	if not burned_mod_val:
		burned_mod_val = ModifierValue.create_new_modifier("burned", ModifierValue.Type.FLAT)
		burned_mod_val.flat_value = stacks
		
		dmg_taken_modifier.add_new_value(burned_mod_val)
