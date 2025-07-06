#damage_effect.gd
class_name DamageEffect
extends Effect

var amount := 0
var receiver_mod_type := Modifier.Type.DMG_TAKEN
var super_effective: bool = false
const SHATTER = preload("res://art/sounds/move_sfx/iceball.mp3")
const BLOCK = preload("res://art/block.ogg")


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target.has_method("take_damage"):
			if target.status_handler.has_status("protected"):
				amount = 0
				target.take_damage(amount, Modifier.Type.NO_MODIFIER)
				SFXPlayer.play(BLOCK)
				Events.battle_text_requested.emit("%s was PROTECTED!" % target.stats.species_id)
				target.status_handler.remove_status("protected")
			if target.status_handler.has_status("froze"):
				target.take_damage(amount*2, receiver_mod_type)
				SFXPlayer.play(SHATTER)
				target.status_handler.remove_status("froze")
			else:
				if amount <= 0:
					amount = 1
				target.take_damage(amount, receiver_mod_type)
				SFXPlayer.pitch_play(sound)
				print("dealt %s damage to %s." % [amount,target.stats.species_id])
				if super_effective:
					Events.camera_shake_requested.emit(amount, 0.5)
				else:
					Events.camera_shake_requested.emit(amount)
				
		
			
