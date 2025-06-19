#block_effect.gd
class_name BlockEffect
extends Effect

var amount := 0
var receiver_mod_type := Modifier.Type.BLOCK_GAINED

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.status_handler.has_and_consume_status("despair"):
			print("Despair detected — block is negated for %s!" % target.stats.species_id)
		else: 
			if target.has_method("gain_block"):
				target.gain_block(amount, receiver_mod_type)
				print("block EFFECT script says the amount is: ", amount)
				SFXPlayer.play(sound)
			if target.status_handler.has_and_consume_status("feeble"):
				print("Feeble detected — block is reduced %s!" % target.stats.species_id)
