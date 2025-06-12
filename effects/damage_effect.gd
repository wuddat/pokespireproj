class_name DamageEffect
extends Effect

var amount := 0
var receiver_mod_type := Modifier.Type.DMG_TAKEN


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("take_damage"):
			target.take_damage(amount, receiver_mod_type)
			SFXPlayer.play(sound)
			print("dealt %s damage to %s." % [amount,target.stats.species_id])
