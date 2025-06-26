# headshot.gd
class_name HeadShot
extends Status

func apply_status(target: Node) -> void:
	super.apply_status(target)

	if not target.status_handler:
		print("❌ No StatusHandler found on target.")
		return

	# Check if body_blow has 10 stacks
	var body_blow_stacks = target.status_handler.get_status_stacks("body_blow")
	if body_blow_stacks and body_blow_stacks >= 10:
		var damage_effect:= FlatDamageEffect.new()
		damage_effect.amount = (target.last_damage_taken) * 2
		damage_effect.sound = preload("res://art/sounds/sfx/supereffective.wav")
		
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] received [color=red]TRIPLE DAMAGE![/color] damage from a [color=goldenrod]HEADSHOT[/color]!" 
		% [
			target.stats.species_id.capitalize(), damage_effect.amount
			])
		
		damage_effect.execute([target])
		target.status_handler.remove_status("body_blow")
		target.status_handler.remove_status("headshot")
