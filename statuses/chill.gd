class_name Chill
extends Status

const FROZE = preload("res://statuses/froze.tres")

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	if target is Enemy:
		if target.is_froze:
			target.status_handler.remove_status("chill")
			return
		if not target.is_froze:
			if target.has_method("show_combat_text"):
				target.show_combat_text("CHILL", Color.AQUAMARINE)
			print("🧊 Chill: First time chilling %s" % target.stats.species_id)

func apply_status(target: Node) -> void:
	print("🔵 Chill: apply_status() called on %s" % target.stats.species_id)
	print("🔵 Current duration: %d" % duration)
	print("🔵 Target is_froze: %s" % target.is_froze)
	
	if target is Enemy:
		if target.is_froze:
			target.status_handler.remove_status("chill")
			return

		if stacks >= 3:
			target.skip_turn = true
			target.is_froze = true
			target.status_handler.remove_status("chill")
			target.status_handler.add_status(FROZE)
			print("❄️ Chill → FROZE triggered!")
			if target.has_method("show_combat_text"):
				target.show_combat_text("FROZE", Color.AQUA)
		else:
			print("🧊 Chill applied but not frozen yet (stacks: %d)" % stacks)
			if target.has_method("show_combat_text"):
				target.show_combat_text("CHILL", Color.AQUAMARINE)
	else:
		print("🔵 Chill: skipping non-enemy target")

	status_applied.emit(self)

func on_end_of_turn(target: Node) -> void:
	var chill = target.status_handler.get_status("chill")
	chill.stacks -= 1
