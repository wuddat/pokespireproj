#block_effect.gd
class_name BlockEffect
extends Effect

var amount: int = 0
var receiver_mod_type := Modifier.Type.BLOCK_GAINED
var base_block: int = 0
var feeble_stacks: int = 0
var feeble_decrement: int = 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.status_handler.has_and_consume_status("despair"):
			print("Despair detected — block is negated for %s!" % target.stats.species_id)
		else: 
			if target.has_method("gain_block"):
				if amount < 0:
					amount = 0
				if amount < base_block:
					feeble_decrement = base_block - amount
				target.gain_block(amount, receiver_mod_type)
				print("block EFFECT script says the amount is: ", amount)
				SFXPlayer.play(sound)
			if target.status_handler.has_status("feeble"):
				for i in range(feeble_decrement):
					target.status_handler.decrement_status("feeble")
				print("Feeble detected — block is reduced %s!" % target.stats.species_id)
