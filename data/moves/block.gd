extends Card


func apply_effects(targets: Array[Node]) -> void:
	var move_data = MoveData.moves.get(id)
	
	if move_data == null:
		push_warning("No move data for card ID: %s" % id)
		return
		
	var block_effect := BlockEffect.new()
	block_effect.amount = move_data.get("power" , 0)
	block_effect.sound = sound
	block_effect.execute(targets)
