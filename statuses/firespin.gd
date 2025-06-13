class_name FireSpin
extends Status

const burn_stacks := 4

func apply_status(target: Node) -> void:
	print("FIRESPIN IS BEING APPLIED HERE")
	var burn = StatusData.STATUS_LOOKUP["burned"].duplicate()
	burn.stacks = burn_stacks
	
	var burn_effect := StatusEffect.new()
	burn_effect.status = burn
	burn_effect.execute([target])
	status_applied.emit(self)
