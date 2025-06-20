class_name Seeded
extends Status

@export var heal_strength := 3

func apply_status(target: Node) -> void:
	var damage_effect:= DamageEffect.new()
	damage_effect.amount = heal_strength
	damage_effect.sound = preload("res://art/axe.ogg")
	damage_effect.execute([target])
	status_applied.emit(self)
