class_name Exposed
extends Status

const MODIFIER := 0.5

func get_tooltip() -> String:
	return tooltip % str(duration)

func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	
	var dmg_taken_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	assert(dmg_taken_modifier, "No dmg taken modifier on %s" % target)
	
	var exposed_mod_val := dmg_taken_modifier.get_value("exposed")
		
	if not exposed_mod_val:
		exposed_mod_val = ModifierValue.create_new_modifier("exposed", ModifierValue.Type.PERCENT_BASED)
		exposed_mod_val.percent_value = MODIFIER
		dmg_taken_modifier.add_new_value(exposed_mod_val)
	
	if not status_changed.is_connected(_on_status_changed):
		status_changed.connect(_on_status_changed.bind(dmg_taken_modifier))
	
	if target.has_method("show_combat_text"):
		target.show_combat_text("EXPOSED", Color.SANDY_BROWN)

#whenever status changes, ask if duration is <=0, and if so, remove status
func _on_status_changed(dmg_taken_modifier: Modifier) -> void:
	if duration <= 0 and dmg_taken_modifier:
		dmg_taken_modifier.remove_value("exposed")
