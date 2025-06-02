class_name EnemyActionPicker
extends Node

@export var enemy: Enemy: set = _set_enemy
@export var target: Node2D: set = _set_target

@onready var total_weight := 0.0


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	#setup_chances()


func get_action() -> EnemyAction:
	var action := get_first_conditional_action()
	if action:
		return action
		
	return get_chance_based_action()


func get_first_conditional_action() -> EnemyAction:
	var action: EnemyAction
	
	for child in get_children():
		action = child as EnemyAction
		if not action or action.type != EnemyAction.Type.CONDITIONAL:
			continue
		
		if action.is_performable():
			return action
	
	return null


func get_chance_based_action() -> EnemyAction:
	var action: EnemyAction
	var roll := randf_range(0.0, total_weight)
	
	for child in get_children():
		action = child as EnemyAction
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		
		if action.accumulated_weight > roll:
			return action
		
	return null


#func setup_actions_from_moves(enemy_ref: Enemy, move_ids: Array[String]) -> void:
	#enemy = enemy_ref
	#target = get_tree().get_first_node_in_group("player")
#
	#for i in range(min(move_ids.size(), get_child_count())):
		#var action_node = get_child(i)
		#var move_id = move_ids[i]
		#var move_data = MoveData.moves.get(move_id, {})
#
		#if action_node.has_method("setup_from_data"):
			#action_node.call("setup_from_data", move_data)

func setup_actions_from_moves(enemy_ref: Enemy, move_ids: Array[String]) -> void:
	enemy = enemy_ref
	target = get_tree().get_first_node_in_group("player")

	# Remove any previously added actions
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()
		await get_tree().process_frame  # Give the scene tree time to remove them

	# Create new actions based on move_ids
	for move_id in move_ids:
		var move_data = MoveData.moves.get(move_id, {})
		if move_data.is_empty():
			push_warning("Missing move data for: " + move_id)
			continue

		var category = move_data.get("category", "attack")  # Default to "attack" if missing
		var action_scene: Script

		match category:
			"attack":
				action_scene = preload("res://enemies/generic_enemy/generic_enemy_attack.gd")
			"block":
				action_scene = preload("res://enemies/generic_enemy/generic_enemy_block.gd")
			_:
				push_warning("Unknown move category for: " + move_id)
				continue

		var action = action_scene.new()
		add_child(action)

		action.enemy = enemy
		action.target = target

		if action.has_method("setup_from_data"):
			action.setup_from_data(move_data)
		else:
			push_warning("Action is missing setup_from_data")

	setup_chances()




func setup_chances() -> void:
	var action: EnemyAction
	
	for child in get_children():
		action = child as EnemyAction
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		
		total_weight += action.chance_weight
		action.accumulated_weight = total_weight


func _set_enemy(value: Enemy) -> void:
	enemy = value
	
	for action in get_children():
		action.enemy = enemy


func _set_target(value: Node2D) -> void:
	target = value
	
	for action in get_children():
		action.target = target
