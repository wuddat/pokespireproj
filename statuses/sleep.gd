class_name Sleep
extends Status

const SLEEP_ICON := preload("res://art/statuseffects/sleep.png")

func get_tooltip() -> String:
	return tooltip % duration

func initialize_status(target: Node) -> void:
	if not target.has_slept:
		target.skip_turn = true
		target.has_slept = true

		var enemy_target := target as Enemy
		enemy_target.intent_ui.icon.texture = SLEEP_ICON
		enemy_target.intent_ui.label.text = ""
		enemy_target.intent_ui.target.texture = null

		print("🟡 Sleep: first time - skipping turn")
		print("🟡 initialize_status stacks: %d" % stacks)
		target.status_handler.remove_status("sleep")

	status_applied.emit(self)


	


func apply_status(target: Node) -> void:
	print("🔵 Sleep: apply_status() called on %s" % target.name)
	print("🔵 Current stacks: %d" % stacks)
	print("🔵 Target has_slept: %s" % target.has_slept)

	if target.has_slept:
		if stacks > 1:
			target.skip_turn = true

			var enemy_target := target as Enemy
			enemy_target.intent_ui.icon.texture = SLEEP_ICON
			enemy_target.intent_ui.label.text = ""
			enemy_target.intent_ui.target.texture = null

			print("🔴 Sleep: second skip triggered - removing status")
			target.status_handler.remove_status("sleep") # 💥 Now safe to remove
		else:
			print("🟢 Sleep: stacked up, but not enough to re-trigger sleep")
	else:
		print("🟢 Sleep: skipping logic — should’ve been handled in initialize_status()")

	status_applied.emit(self)
