#damage_effect.gd
class_name DamageEffect
extends Effect

var amount := 0
var receiver_mod_type := Modifier.Type.DMG_TAKEN
const SHATTER = preload("res://art/sounds/move_sfx/iceball.mp3")

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("take_damage"):
			if target.status_handler.has_status("froze"):
				target.take_damage(amount*2, receiver_mod_type)
				SFXPlayer.play(SHATTER)
				target.status_handler.remove_status("froze")
			else:
				target.take_damage(amount, receiver_mod_type)
				SFXPlayer.play(sound)
				print("dealt %s damage to %s." % [amount,target.stats.species_id])
		
			
