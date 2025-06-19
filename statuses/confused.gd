class_name ConfusedStatus
extends Status

const CONFUSED_ICON := preload("res://art/statuseffects/confused-effect.png")

func get_tooltip() -> String:
	return "This unit is confused and may attack the wrong target!"

func initialize_status(target: Node) -> void:
	if not (target is Enemy):
		return

	var enemy_target := target as Enemy
	enemy_target.is_confused = true
	if enemy_target.enemy_action_picker:
		print("[CONFUSE] applied to: ", enemy_target.stats.species_id)
		enemy_target.enemy_action_picker.select_confused_target()

		if enemy_target.current_action:
			var confused_target = enemy_target.enemy_action_picker.target
			enemy_target.current_action.target = confused_target
			print("[CONFUSE] updated enemy target to: ", enemy_target.stats.species_id)
	enemy_target.current_action.update_intent_text()
	


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1
		print(status.id," effect applied and duration reduced by 1")
		
