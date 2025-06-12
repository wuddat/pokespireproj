class_name EnemyActionPicker
extends Node

@export var enemy: Enemy: set = _set_enemy
@export var target: Node2D: set = _set_target

@onready var total_weight := 0.0
var target_pool: Array[PokemonBattleUnit] = []
var confused_target_pool := []


func _ready() -> void:
	await wait_for_party_handler()
	_initialize_connections()
	refresh_target_pool()


func wait_for_party_handler() -> void:
	await get_tree().process_frame
	while get_tree().get_first_node_in_group("party_handler") == null:
		await get_tree().process_frame


func refresh_target_pool() -> void:
	var party_handler = get_tree().get_first_node_in_group("party_handler")
	var enemy_handler = get_tree().get_first_node_in_group("enemy_handler")
	
	target_pool.clear()
	confused_target_pool.clear()
	
	if party_handler:
		target_pool = party_handler.get_active_pokemon_nodes().filter(
			func(unit): return is_instance_valid(unit) and unit.stats and unit.stats.health > 0
		)
		confused_target_pool += target_pool.map(func(n): return n as Node)
		
	if enemy_handler:
		var enemies = enemy_handler.get_children().filter(
			func(n): return n is Enemy and n.stats and n.stats.health > 0
		)
		confused_target_pool += enemies.map(func(n): return n as Node)
		
	confused_target_pool = confused_target_pool.filter(
		func(n): return is_instance_valid(n)
	)
	#print("🎯 Refreshed target_pool:", target_pool.map(func(n): return n.name))
	print("🤪 Refreshed confused_target_pool:", confused_target_pool.map(func(n): return n.name))
	select_valid_target()


func select_valid_target() -> void:
	var valid_targets = target_pool.filter(
		func(pkmn): return is_instance_valid(pkmn) and pkmn.stats and pkmn.stats.health > 0
	)
	if valid_targets.is_empty():
		target = null
		for action in get_children():
			action.target = null
		#print("🚫 No valid targets in target_pool!")
		return
	
	target = valid_targets.pick_random()
	#print("🎯 Selected valid target:", target.stats.species_id)
	for action in get_children():
		action.target = target


func select_confused_target() -> void:
	if confused_target_pool.is_empty():
		target = null
		#print("🤯 No valid targets in confused_target_pool!")
	else:
		refresh_target_pool()
		target = confused_target_pool.pick_random()
		print("🤪 CONFUSED! Selected target:", target.stats.species_id)
	for action in get_children():
		action.target = target


func _on_pokemon_fainted(_fainted_pokemon: Node) -> void:
	refresh_target_pool()


func get_action() -> EnemyAction:
	var action := get_first_conditional_action()
	if action:
		return action
	return get_chance_based_action()


func get_first_conditional_action() -> EnemyAction:
	for child in get_children():
		var action = child as EnemyAction
		if action and action.type == EnemyAction.Type.CONDITIONAL and action.is_performable():
			return action
	return null


func get_chance_based_action() -> EnemyAction:
	var roll := randf_range(0.0, total_weight)
	for child in get_children():
		var action = child as EnemyAction
		if action and action.type == EnemyAction.Type.CHANCE_BASED and action.accumulated_weight > roll:
			return action
	return null


func setup_actions_from_moves(enemy_ref: Enemy, move_ids: Array[String]) -> void:
	enemy = enemy_ref

	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()
		await get_tree().process_frame

	for move_id in move_ids:
		var move_data = MoveData.moves.get(move_id, {})
		if move_data.is_empty():
			push_warning("Missing move data for: " + move_id)
			continue

		var category = move_data.get("category", "attack")
		var action_scene: Script

		match category:
			"attack":
				action_scene = preload("res://enemies/generic_enemy/generic_enemy_attack.gd")
			"defense":
				action_scene = preload("res://enemies/generic_enemy/generic_enemy_block.gd")
			_:
				push_warning("Unknown move category for: " + move_id)
				continue

		var action = action_scene.new()
		add_child(action)
		
		action.enemy = enemy
		var target_type = move_data.get("target", "enemy")
		if target_type == "all_enemies":
			action.targets = target_pool.duplicate()
		else:
			action.target = target

		if action.has_method("setup_from_data"):
			action.setup_from_data(move_data)
		else:
			push_warning("Action is missing setup_from_data")

	setup_chances()

func setup_chances() -> void:
	for child in get_children():
		var action = child as EnemyAction
		if action and action.type == EnemyAction.Type.CHANCE_BASED:
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

func _on_pokemon_switch(pkmn: PokemonStats) -> void:
	refresh_target_pool()
	select_valid_target()

func _initialize_connections() -> void:
	if not Events.player_pokemon_switch_completed.is_connected(_on_pokemon_switch):
		Events.player_pokemon_switch_completed.connect(_on_pokemon_switch)
		
	if not Events.party_pokemon_fainted.is_connected(_on_pokemon_fainted):
		Events.party_pokemon_fainted.connect(_on_pokemon_fainted)
