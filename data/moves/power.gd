extends Card


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var move_data = MoveData.moves.get(id)
	var _base_damage = move_data.get("power" , 0)
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
	
	#apply status effect if any on card
	for status_effect in status_effects:
		if status_effect:
			var stat_effect := StatusEffect.new()
			var status_to_apply := status_effect.duplicate()
			stat_effect.status = status_to_apply
			stat_effect.sound = sound
			stat_effect.execute(targets)
	
