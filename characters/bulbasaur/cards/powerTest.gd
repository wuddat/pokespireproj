extends Card

const status = preload("res://statuses/enraged.tres")

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var status_effect := StatusEffect.new()
	var status_to_apply := status.duplicate()
	status_effect.status = status_to_apply
	status_effect.sound = preload("res://art/axe.ogg")
	status_effect.execute(targets)
	print(target, "enrages")
