class_name OHKO
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
		
	var damage_effect:= DamageEffect.new()
	damage_effect.amount = target.stats.max_health
	damage_effect.sound = preload("res://art/sounds/move_sfx/ohko.mp3")
	damage_effect.execute([target])
	status_applied.emit(self)
