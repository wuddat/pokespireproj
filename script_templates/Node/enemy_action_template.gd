# meta-name: EnemyAction
# meta-description: Action to be performed by enemy during turn
extends EnemyAction


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	
	SFXPlayer.play(sound)
	
	Events.enemy_action_completed.emit(enemy)


# If the enemy has dynamic intent text - override base behavior here
# ex. attack actions, Player's DMG_TAKEN mod will change the resulting dmg num
func update_intent_text() -> void:
	var player := target as Player
	if not player:
		return
	
	var modified_dmg := player.modifier_handler.get_modified_value(6, Modifier.Type.DMG_TAKEN)
	intent.current_text = intent.base_text % modified_dmg
