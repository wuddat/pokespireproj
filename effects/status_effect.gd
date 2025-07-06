#status_effect.gd
class_name StatusEffect
extends Effect

var status: Status
var source: Node
var enemy_placeholder: String = "Enemy [color=red]%s[/color]"

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player or target is PokemonBattleUnit:
			var unique_status = status.duplicate()
			unique_status.status_source = source
			if not target.status_handler.has_status(status.id) and status.id == "sleep" and !target.has_slept:
				status.display_string = " fell asleep!"
				if target is Enemy:
					Events.battle_text_requested.emit((enemy_placeholder + "%s") % [target.stats.species_id.capitalize(),status.display_string])
				else:
					Events.battle_text_requested.emit("%s%s" % [target.stats.species_id.capitalize(),status.display_string])
					
			elif not target.status_handler.has_status(status.id):
				if target is Enemy:
					Events.battle_text_requested.emit((enemy_placeholder + "%s") % [target.stats.species_id.capitalize(),status.display_string])
				else:
					Events.battle_text_requested.emit("%s%s" % [target.stats.species_id.capitalize(),status.display_string])
			else:
				Events.battle_text_requested.emit("")
			target.status_handler.add_status(unique_status)
			SFXPlayer.play(sound)
			print("[STATUS_EFFECT]%s applied to %s" % [status.id, target.stats.species_id])
			if "unit_status_indicator" in target:
				target.unit_status_indicator.update_status_display(target)
