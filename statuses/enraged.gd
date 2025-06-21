class_name EnragedStatus
extends Status

const ATTACK_POWER_STATUS = preload("res://statuses/attack_up.tres")

var stacks_per_turn := 2

func get_tooltip() -> String:
	return tooltip % stacks_per_turn

func apply_status(target: Node) -> void:
	print("applied enraged and increased atk pwr ")
	Events.battle_text_requested.emit("%s received [color=red]2 ATKPWR[/color]!" % [target.stats.species_id.capitalize()])
	var status_effect := StatusEffect.new()
	var atkpwr := ATTACK_POWER_STATUS.duplicate()
	atkpwr.stacks = stacks_per_turn
	status_effect.status = atkpwr
	status_effect.execute([target])
	
	status_applied.emit(self)
