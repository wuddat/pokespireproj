#status_effect.gd
class_name StatusEffect
extends Effect

var status: Status
var source: Node


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player or target is PokemonBattleUnit:
			var unique_status = status.duplicate()
			unique_status.status_source = source
			if not target.status_handler.has_status(status.id):
				Events.battle_text_requested.emit("%s%s" % [target.stats.species_id.capitalize(),status.display_string])
			else:
				Events.battle_text_requested.emit("")
			target.status_handler.add_status(unique_status)
			SFXPlayer.play(sound)
			print("%s applied to %s" % [status.id, target.stats.species_id])
