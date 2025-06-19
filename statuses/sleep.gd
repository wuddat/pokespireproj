class_name Sleep
extends Status

const SLEEP_ICON := preload("res://art/statuseffects/sleep.png")

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	if target is Enemy:
		if target.is_asleep:
			target.status_handler.remove_status("sleep")
			return
		if not target.has_slept:
			target.skip_turn = true
			target.is_asleep = true
			target.status_handler.remove_status("sleep")
			print("🟢 Sleep: First application - skipping and flagging")


func apply_status(target: Node) -> void:
	print("🔵 Sleep: apply_status() called on %s" % target.name)
	print("🔵 Current stacks: %d" % stacks)
	print("🔵 Target has_slept: %s" % target.has_slept)
	
	
	if target is Enemy:
		if target.is_asleep:
			target.status_handler.remove_status("sleep")
			return
		if target.has_slept:
			if stacks > 1:
				target.skip_turn = true
				target.is_asleep = true
				var enemy_target := target as Enemy
				target.status_handler.remove_status("sleep")
		else:
			print("🟢 Sleep: stacked up, but not enough to re-trigger sleep")
	else:
		print("🟢 Sleep: skipping logic — should’ve been handled in initialize_status()")

	status_applied.emit(self)
