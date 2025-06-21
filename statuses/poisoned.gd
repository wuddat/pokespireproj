class_name PoisonedStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	

	var damage_effect:= DamageEffect.new()
	damage_effect.amount = duration
	damage_effect.sound = preload("res://art/axe.ogg")
	
	Events.battle_text_requested.emit("Enemy [color=red]%s[/color] received [color=red]%s[/color] damage from [color=purple]POISON[/color]!" 
	% [
		target.stats.species_id.capitalize(), damage_effect.amount
		])
	
	damage_effect.execute([target])
	status_applied.emit(self)
