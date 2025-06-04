extends EnemyAction

@export var damage := 2


func setup_from_data(data: Dictionary) -> void:
	var damage_display = "%s"
	damage = data.get("power", 0)
	#print("data passed to setup as: ",data)
	sound = preload("res://art/sounds/VineWhip2.wav")
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0
	
	intent = Intent.new()
	intent.base_text = damage_display
	intent.current_text = str(damage)
	if damage <= 5:
		intent.icon = preload("res://art/tile_0103.png")
	elif damage <= 10:
		intent.icon = preload("res://art/tile_0104.png")
	elif damage <= 15:
		intent.icon = preload("res://art/tile_0118.png")
	else:
		intent.icon = preload("res://art/tile_0117.png")
		
		

func perform_action() -> void:
	if not enemy or not target:
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound = sound
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_interval(.25)
	tween.tween_property(enemy, "global_position", start, .4)
	
	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	var player := target as Player
	if not player:
		return
	
	var modified_dmg := player.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_TAKEN)
	intent.current_text = intent.base_text % modified_dmg
