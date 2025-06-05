class_name BlockEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player or target is PokemonBattleUnit:
			target.stats.block += amount
			SFXPlayer.play(sound)
			print("block for ", amount)
