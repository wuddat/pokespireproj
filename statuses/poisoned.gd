class_name PoisonedStatus
extends Status

func get_tooltip() -> String:
	return tooltip % duration

func apply_status(target: Node) -> void:
	

	var damage_effect:= FlatDamageEffect.new()
	damage_effect.amount = duration
	damage_effect.sound = preload("res://art/axe.ogg")
	
	Events.battle_text_requested.emit("Enemy [color=red]%s[/color] received [color=red]%s[/color] damage from [color=purple]POISON[/color]!" 
	% [
		target.stats.species_id.capitalize(), damage_effect.amount
		])
	
	damage_effect.execute([target])
	if target.has_method("show_combat_text"):
		target.show_combat_text("POISONED", Color.PURPLE)
	status_applied.emit(self)
