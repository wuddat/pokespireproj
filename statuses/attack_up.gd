class_name AttackPower
extends Status

func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)
	if target.has_method("show_combat_text"):
		target.show_combat_text("ATK UP!", Color.RED)

func _on_status_changed(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	
	var dmg_dealt_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(dmg_dealt_modifier, "No dmg dealt modifier on %s" % target)
	
	var atk_pwr_mod_value := dmg_dealt_modifier.get_value("attack_up")
	
	if not atk_pwr_mod_value:
		atk_pwr_mod_value = ModifierValue.create_new_modifier("attack_up", ModifierValue.Type.FLAT)
	
	atk_pwr_mod_value.flat_value = stacks
	dmg_dealt_modifier.add_new_value(atk_pwr_mod_value)
