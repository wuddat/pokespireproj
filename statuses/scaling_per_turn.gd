class_name Scaling
extends Status

const ATK_PWR = preload("res://statuses/attack_up.tres")
const DEX = preload("res://statuses/dexterity.tres")

var stacks_per_turn := 2

func get_tooltip() -> String:
	return tooltip % stacks_per_turn

func apply_status(target: Node) -> void:
	print("applied enraged and increased atk pwr ")
	
	var status_effect := StatusEffect.new()
	status_effect.source = target
	var atkpwr := ATK_PWR.duplicate()
	atkpwr.stacks = stacks_per_turn
	status_effect.status = atkpwr
	status_effect.execute([target])
	var status_effect_2 := StatusEffect.new()
	status_effect_2.source = target
	var dex := DEX.duplicate()
	dex.stacks = stacks_per_turn
	status_effect_2.status = dex
	status_effect_2.execute([target])
	status_applied.emit(self)
