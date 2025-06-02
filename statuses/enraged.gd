class_name EnragedStatus
extends Status

const ATTACK_POWER_STATUS = preload("res://statuses/attack_power.tres")

var stacks_per_turn := 2

func apply_status(target: Node) -> void:
	print("applied enraged and increased atk pwr ")
	
	var status_effect := StatusEffect.new()
	var atkpwr := ATTACK_POWER_STATUS.duplicate()
	atkpwr.stacks = stacks_per_turn
	status_effect.status = atkpwr
	status_effect.execute([target])
	
	status_applied.emit(self)
