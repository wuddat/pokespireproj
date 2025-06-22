#flat_damage_effect.gd
class_name FlatDamageEffect
extends Effect

var amount := 0
var _receiver_mod_type = Modifier.Type.NO_MODIFIER

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("take_damage"):
				target.take_damage(amount, _receiver_mod_type)
				SFXPlayer.play(sound)
				print("dealt %s damage to %s." % [amount,target.stats.species_id])
		
			
