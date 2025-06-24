#enemy_handler.gd
class_name EnemyHandler
extends Node2D

@onready var right_panel: VBoxContainer = $"../StatUI/RightPanel"
@onready var party_handler: PartyHandler = $"../PartyHandler"

var stats_ui_scn := preload("res://scenes/ui/health_bar_ui.tscn")
var acting_enemies: Array[Enemy] = []
var caught_pokemon: Array[PokemonStats] = []
var bench_pokemon: Array[String] = []
var battle_stats: BattleStats = null

var enemy_text_delay: float = 0.4

func _ready() -> void:
	Events.enemy_fainted.connect(_on_enemy_fainted)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_hand_discarded.connect(_on_player_hand_drawn)
	Events.pokemon_captured.connect(_on_pokemon_captured)
	Events.party_pokemon_fainted.connect(_on_party_pokemon_fainted)

func setup_enemies(bat_stats: BattleStats) -> void:
	if not bat_stats:
		return
	
	battle_stats = bat_stats.duplicate()
	
	for enemy: Enemy in get_children():
		enemy.queue_free()
	
	var species_ids:Array[String] = []
	if battle_stats.is_trainer_battle:
		battle_stats.assign_enemy_pkmn_party()
		species_ids = battle_stats.enemy_pkmn_party.duplicate()
	else: 
		species_ids = Pokedex.get_species_for_tier(battle_stats.battle_tier)
	
	var all_new_enemies := battle_stats.enemies.instantiate()
	var max_spawn:= all_new_enemies.get_child_count()
	var enemy_nodes := all_new_enemies.get_children()
	
	if battle_stats.is_trainer_battle:
		var species_to_spawn := species_ids.slice(0, max_spawn)
		bench_pokemon = species_ids.slice(max_spawn)
	
		for i in range(species_to_spawn.size()):
			_spawn_enemy(species_to_spawn[i], enemy_nodes[i])
			
	else:
		for new_enemy: Node2D in enemy_nodes:
			var species_id = species_ids.pick_random()
			_spawn_enemy(species_id, new_enemy)
		all_new_enemies.queue_free()


func reset_enemy_actions() -> void:
	var enemy: Enemy
	for child in get_children():
		enemy = child as Enemy
		enemy.current_action = null
		enemy.update_action()


func start_turn() -> void:
	if get_child_count() == 0:
		return
	
	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)
	
	_start_next_enemy_turn()


func shift_enemies() -> void:
	var enemies: Array[Enemy] = []
	var positions: Array[Vector2] = []
	var target_positions: Array[String] = []
	
	for child in get_children():
		if child is Enemy:
			enemies.append(child)
			positions.append(child.spawn_coords)
			target_positions.append(child.enemy_action_picker.current_target_pos)

	if enemies.size() < 2:
		return

	# Sort by spawn_coords.x for consistent left-to-right order
	enemies.sort_custom(func(a, b): return a.spawn_coords.x < b.spawn_coords.x)
	positions.sort_custom(func(a, b): return a.x < b.x)

	# Rotate enemies AND target positions together
	var new_order := enemies.duplicate()
	var new_target_positions := target_positions.duplicate()
	new_order.push_front(new_order.pop_back())
	new_target_positions.push_front(new_target_positions.pop_back())

	for i in range(new_order.size()):
		var enemy: Enemy = new_order[i]
		var new_position: Vector2 = positions[i]
		var new_target_pos: String = new_target_positions[i]

		enemy.spawn_coords = new_position
		enemy.enemy_action_picker.current_target_pos = new_target_pos

		print("%s reassigned to POS: %s" % [enemy.stats.species_id.capitalize(), new_target_pos])

		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(enemy, "global_position", new_position, 0.4)


func _spawn_enemy(species_id: String, enemy_node: Node2D) -> void:
	var enemy: Enemy = preload("res://scenes/enemy/enemy.tscn").instantiate()
	if enemy_node:
		enemy.global_position = enemy_node.global_position
	
	var stats := preload("res://enemies/generic_enemy/generic_enemy.tres").duplicate()
	stats.species_id = species_id
	stats.load_from_pokedex(Pokedex.get_pokemon_data(species_id))
	enemy.stats = stats
	
	add_child(enemy)

	var ui := stats_ui_scn.instantiate() as HealthBarUI
	right_panel.add_child(ui)
	ui.icon.position = Vector2(60, 7)
	ui.update_stats(stats)

	if not enemy.stats.stats_changed.is_connected(ui.update_stats):
		enemy.stats.stats_changed.connect(func(): ui.update_stats(enemy.stats))
	enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))


func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		Events.enemy_turn_ended.emit()
		return
	
	Events.battle_text_requested.emit("Enemy Turn: [color=red]%s[/color]" % acting_enemies[0].stats.species_id.capitalize())
	#await get_tree().create_timer(.5).timeout
	await acting_enemies[0].status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func _on_enemy_statuses_applied(type: Status.Type, enemy: Enemy) -> void:
	match type:
		Status.Type.START_OF_TURN:
			#if enemy.status_handler.has_any_status():
				#await get_tree().create_timer(2).timeout
			enemy.do_turn()
		Status.Type.END_OF_TURN:
			acting_enemies.erase(enemy)
			_start_next_enemy_turn()


func _on_enemy_fainted(enemy: Enemy) -> void:
	print("Enemy fainted: ", enemy.stats.species_id)
	if !enemy.is_caught:
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] FAINTED!" % enemy.stats.species_id.capitalize())
	
	if battle_stats.is_trainer_battle and bench_pokemon.size() > 0:
		await get_tree().create_timer(0.5).timeout
		var next_species = bench_pokemon.pop_front()
		Events.battle_text_requested.emit("Trainer sends out [color=red]%s[/color]!" % next_species.capitalize())
		_spawn_enemy(next_species, enemy)
	
	var battling_pokemon := party_handler.get_active_pokemon_nodes()
	if battling_pokemon:
		for battler in battling_pokemon:
			if battler.has_method("on_enemy_defeated"):
				battler.on_enemy_defeated(enemy)
	
	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	enemy.queue_free()
	child_order_changed.emit()
	
	if is_enemy_turn:
		_start_next_enemy_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)

func _on_party_pokemon_fainted(pkmn: PokemonBattleUnit):
	if acting_enemies.size() > 0:
		for enemy in acting_enemies:
			if enemy.current_action.target == pkmn:
				enemy.enemy_action_picker.select_valid_target()

func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()

func _on_pokemon_captured(stats: PokemonStats) -> void:
	caught_pokemon.append(stats.duplicate())
