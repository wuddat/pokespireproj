class_name Critical
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	var crit_mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var mod_val := ModifierValue.create_new_modifier("critical", ModifierValue.Type.PERCENT_BASED)
	mod_val.percent_value = 1.0
	crit_mod.add_new_value(mod_val)
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)

func _on_status_changed(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	
	var crit_mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(crit_mod, "No block modifier on %s" % target)
	
	var mod_val := crit_mod.get_value("critical")
	
	if not mod_val:
		mod_val = ModifierValue.create_new_modifier("critical", ModifierValue.Type.PERCENT_BASED)

	mod_val.percent_value = 1.0
	crit_mod.add_new_value(mod_val)
