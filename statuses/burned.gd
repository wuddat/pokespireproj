class_name Burned
extends Status


func get_tooltip() -> String:
	return tooltip % stacks

func initialize_status(target: Node) -> void:
	assert(target.get("modifier_handler"), "No modifiers on %s" % target)
	check_and_apply_burn_mods(target)
	

func apply_status(target: Node) -> void:
	check_and_apply_burn_mods(target)


func check_and_apply_burn_mods(target: Node) -> void:
	var dmg_taken_modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	assert(dmg_taken_modifier, "No dmg taken modifier on %s" % target)

	var burned_mod_val := dmg_taken_modifier.get_value("burned")
	if not burned_mod_val:
		burned_mod_val = ModifierValue.create_new_modifier("burned", ModifierValue.Type.FLAT)
		dmg_taken_modifier.add_new_value(burned_mod_val)

	# 🔁 Always keep flat_value in sync with stacks
	burned_mod_val.flat_value = stacks

	print("🔥 Burned: applied with %d stacks" % stacks)
	status_applied.emit(self)
