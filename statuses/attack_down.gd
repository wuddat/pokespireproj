class_name AttackDown
extends Status

func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)


func _on_status_changed(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)

	var dmg_dealt_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_DEALT)
	assert(dmg_dealt_modifier, "No dmg dealt modifier on %s" % target)

	var atk_down_mod := dmg_dealt_modifier.get_value("attack_down")

	if not atk_down_mod:
		atk_down_mod = ModifierValue.create_new_modifier("attack_down", ModifierValue.Type.FLAT)

	# 👇 NEGATIVE stacks to reduce outgoing damage
	atk_down_mod.flat_value = -stacks
	dmg_dealt_modifier.add_new_value(atk_down_mod)
