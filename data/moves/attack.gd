extends Card


func apply_effects(targets: Array[Node]) -> void:
	var move_data = MoveData.moves.get(id)
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
	
	var damage_effect := DamageEffect.new()
	damage_effect.amount = move_data.get("power" , 0)
	damage_effect.sound = sound
	damage_effect.execute(targets)
	print(damage_effect.amount)
	
	#apply status effect if any on card
	for status_effect in status_effects:
		if status_effect:
			var stat_effect := StatusEffect.new()
			var status_to_apply := status_effect.duplicate()
			stat_effect.status = status_to_apply
			stat_effect.execute(targets)
	
