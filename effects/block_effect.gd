class_name BlockEffect
extends Effect

var amount := 0
var receiver_mod_type := Modifier.Type.BLOCK_GAINED

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("gain_block"):
			target.gain_block(amount, receiver_mod_type)
			SFXPlayer.play(sound)
			print("block for ", amount)
