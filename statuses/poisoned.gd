class_name PoisonedStatus
extends Status


func apply_status(target: Node) -> void:
		
	var damage_effect:= DamageEffect.new()
	damage_effect.amount = duration
	damage_effect.sound = preload("res://art/axe.ogg")
	damage_effect.execute([target])
	
	status_applied.emit(self)
