extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = 6
	damage_effect.sound = sound
	damage_effect.execute(targets)
	var tackle = MoveData.moves["tackle"]
