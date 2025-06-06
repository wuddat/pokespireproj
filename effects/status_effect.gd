class_name StatusEffect
extends Effect

var status: Status


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player or target is PokemonBattleUnit:
			target.status_handler.add_status(status)
			SFXPlayer.play(sound)
			print("%s applied" % status)

func enemy_execute(targets: Array[PokemonBattleUnit]) -> void:
	for target in targets:
		if not target:
			continue
		if target is PokemonBattleUnit:
			target.status_handler.add_status(status)
			SFXPlayer.play(sound)
			print("%s applied to enemy target" % status)
