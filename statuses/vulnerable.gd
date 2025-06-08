class_name Vulnerable
extends Status

const BONUS_MULTIPLIER := 1.0 # Makes it 2x total

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	var dmg_taken_mod: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	var mod_val := ModifierValue.create_new_modifier("vulnerable", ModifierValue.Type.PERCENT_BASED)
	mod_val.percent_value = BONUS_MULTIPLIER
	dmg_taken_mod.add_new_value(mod_val)

func apply_status(target: Node) -> void:
	status_applied.emit(self)
	# Remove effect after first damage taken
	target.status_handler.queue_remove_on_next_damage("vulnerable")
