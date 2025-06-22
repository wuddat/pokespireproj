#flat_damage_effect.gd
class_name FlatDamageEffect
extends Effect

var amount := 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("take_damage"):
				target.take_damage(amount)
				SFXPlayer.play(sound)
				print("dealt %s FLAT damage to %s." % [amount,target.stats.species_id])
		
			
