class_name Critical
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	var crit_mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	var mod_val := ModifierValue.create_new_modifier("critical", ModifierValue.Type.PERCENT_BASED)
	mod_val.percent_value = 1.0
	crit_mod.add_new_value(mod_val)

func apply_status(_target: Node) -> void:
	status_applied.emit(self)
