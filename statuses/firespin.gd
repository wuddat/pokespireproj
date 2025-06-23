class_name FireSpin
extends Status

const burn_stacks := 4

func apply_status(target: Node) -> void:
	print("FIRESPIN IS BEING APPLIED HERE")
	var burn = preload("res://statuses/burned.tres").duplicate()
	burn.stacks = burn_stacks
	
	if target is Enemy:
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] [color=orange]BURNS[/color] in the flames!" 
	% [target.stats.species_id.capitalize()])
	
	if target is PokemonBattleUnit:
		Events.battle_text_requested.emit("Ally %s [color=orange]BURNS[/color] in the flames!" 
	% [target.stats.species_id.capitalize()])
	var burn_effect := StatusEffect.new()
	burn_effect.source = target
	burn_effect.status = burn
	burn_effect.execute([target])
	status_applied.emit(self)
