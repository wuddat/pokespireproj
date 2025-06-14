#status_effect.gd
class_name StatusEffect
extends Effect

var status: Status


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player or target is PokemonBattleUnit:
			var unique_status = status.duplicate()
			target.status_handler.add_status(unique_status)
			SFXPlayer.play(sound)
			print("%s applied to %s" % [status.id, target.stats.species_id])
