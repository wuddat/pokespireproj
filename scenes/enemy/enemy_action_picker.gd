#enemy_action_picker.gd
class_name EnemyActionPicker
extends Node

@export var enemy: Enemy: set = _set_enemy
@export var target: Node2D: set = _set_target

@onready var total_weight := 0.0
var target_pool = []
var confused_target_pool := []
var current_target_pos: String
var player_party_pool: = []
var enemy_ally_pool: Array[Node] = []


func _ready() -> void:
	await wait_for_party_handler()
	_initialize_connections()
	refresh_target_pool()
	select_valid_target()


func wait_for_party_handler() -> void:
	await get_tree().process_frame
	while get_tree().get_first_node_in_group("party_handler") == null:
		await get_tree().process_frame


func refresh_target_pool() -> void:
	var party_handler = get_tree().get_first_node_in_group("party_handler")
	var enemy_handler = get_tree().get_first_node_in_group("enemy_handler")
	
	target_pool.clear()
	confused_target_pool.clear()
	player_party_pool.clear()
	enemy_ally_pool.clear()
	
	if party_handler:
		player_party_pool = party_handler.get_active_pokemon_nodes()
		player_party_pool.sort_custom(func(a, b): return a.spawn_position < b.spawn_position)
		player_party_pool = player_party_pool.filter(
			func(unit): return is_instance_valid(unit) and unit.stats and unit.stats.health > 0
		)
		target_pool = player_party_pool.duplicate()
		confused_target_pool += player_party_pool
		
	if enemy_handler:
		enemy_ally_pool = enemy_handler.get_children().filter(
			func(n): return n is Enemy and n.stats and n.stats.health > 0
		)
		confused_target_pool += enemy_ally_pool
	
	confused_target_pool = confused_target_pool.filter(func(n): return is_instance_valid(n))



func select_valid_target() -> void:
	var valid_targets = target_pool.filter(
		func(pkmn): return is_instance_valid(pkmn) and pkmn.stats and pkmn.stats.health > 0
	)
	if valid_targets.is_empty():
		#print("🚫 ENEMY_ACTION_PICKER.GD No valid targets found!")
		target = null
		for action in get_children():
			action.target = null
		return
	
	target = RNG.array_pick_random(valid_targets)
	current_target_pos = target.spawn_position
	#print("🎯 ENEMY_ACTION_PICKER.GD Picker selected new valid target: %s" % target.stats.species_id)
#
	for action in get_children():
		action.target = target
		#print("ENEMY_ACTION_PICKER.GD Applied new target to action: %s" % action)


func _on_party_shifted() -> void:
	refresh_target_pool()
	for tar in target_pool:
		print("target_pool: ", tar.stats.species_id)
	var new_target: PokemonBattleUnit = null
	if not is_instance_valid(target):
		return
	else: print("%s current_target_pos is %s for %s: " % [enemy.stats.species_id.capitalize(), current_target_pos, target.stats.species_id])
	
	for target_candidate in target_pool:
		if target_candidate.spawn_position == current_target_pos:
			new_target = target_candidate
			break
	if not new_target and not target_pool.is_empty():
		new_target = target_pool.front()
		current_target_pos = new_target.spawn_position
		print("⚠️ Fallback! No one at desired spot. Defaulting to: ", new_target.stats.species_id)

	if new_target:
		target = new_target
		for action in get_children():
			action.target = new_target
		print("🔄 _on_party_shifted: %s matched new target at position %s -> %s" % [enemy.stats.species_id.capitalize(),current_target_pos, new_target.stats.species_id])
	else:
		print("❌ _on_party_shifted: no valid target found at all.")




func select_confused_target() -> void:
	if confused_target_pool.is_empty():
		target = null
		#print("🤯 No valid targets in confused_target_pool!")
	else:
		refresh_target_pool()
		target = RNG.array_pick_random(confused_target_pool)
		#print("🤪 CONFUSED! Selected target:", target.stats.species_id)
	for action in get_children():
		action.target = target


func _on_pokemon_fainted(_fainted_pokemon: Node) -> void:
	refresh_target_pool()
	select_valid_target()

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
	var roll := RNG.instance.randf_range(0.0, total_weight)
	for child in get_children():
		var action = child as EnemyAction
		if action and action.type == EnemyAction.Type.CHANCE_BASED and action.accumulated_weight > roll:
			return action
	return null


# Update setup_actions_from_moves in enemy_action_picker.gd
func setup_actions_from_moves(enemy_ref: Enemy, move_ids: Array[String]) -> void:
	refresh_target_pool()
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
		var action = EnemyActionFactory.create_action(category, move_data)
		
		if not action:
			continue
			
		add_child(action)
		action.enemy = enemy
		
		var target_type = move_data.get("target", "enemy")
		resolve_action_targets(action, target_type)

	setup_chances()


func resolve_action_targets(action: EnemyAction, target_type: String) -> void:
	match target_type:
		"single_enemy", "enemy":
			action.target = target
		"all_enemies":
			action.targets = player_party_pool.duplicate()
		"all_allies", "allies":
			action.targets = enemy_ally_pool.duplicate()
		"all":
			action.targets = player_party_pool.duplicate() + enemy_ally_pool.duplicate()
		"self":
			action.targets = [enemy]
		_:
			action.target = target
			print("[ENEMYACTIONPICKER]: Resolve action target error: target_type string invalid")


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

func _on_pokemon_switch(_pkmn: PokemonStats) -> void:
	refresh_target_pool()
	_on_party_shifted()

func _initialize_connections() -> void:
	if not Events.player_pokemon_switch_completed.is_connected(_on_pokemon_switch):
		Events.player_pokemon_switch_completed.connect(_on_pokemon_switch)
		
	if not Events.party_pokemon_fainted.is_connected(_on_pokemon_fainted):
		Events.party_pokemon_fainted.connect(_on_pokemon_fainted)
	
	if not Events.party_shifted.is_connected(_on_party_shifted):
		Events.party_shifted.connect(_on_party_shifted)
