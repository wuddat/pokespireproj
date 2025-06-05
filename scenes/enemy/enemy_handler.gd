class_name EnemyHandler
extends Node2D

@onready var right_panel: VBoxContainer = $"../StatUI/RightPanel"

var stats_ui_scn := preload("res://scenes/ui/health_bar_ui.tscn")
var acting_enemies: Array[Enemy] = []

func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_hand_discarded.connect(_on_player_hand_drawn)


func setup_enemies(battle_stats: BattleStats) -> void:
	if not battle_stats:
		return
	
	for enemy: Enemy in get_children():
		enemy.queue_free()
	
	var all_new_enemies := battle_stats.enemies.instantiate()
	var species_ids = Pokedex.pokedex.keys()
	
	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		var random_species := species_ids.pick_random() as String
		
		var new_stats := preload("res://enemies/generic_enemy/generic_enemy.tres").duplicate()
		new_stats.species_id = random_species
		new_enemy_child.stats = new_stats
		
		add_child(new_enemy_child)
		
		var ui := stats_ui_scn.instantiate() as HealthBarUI
		
		right_panel.add_child(ui)
		
		ui.update_stats(new_enemy_child.stats)
		print("Added StatsUI for", new_enemy_child)
		print("Parent node:", ui.get_parent())

		if not new_enemy_child.stats.stats_changed.is_connected(ui.update_stats):
			new_enemy_child.stats.stats_changed.connect(func(): ui.update_stats(new_enemy_child.stats))
		
		new_enemy_child.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(new_enemy_child))
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
	

func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		Events.enemy_turn_ended.emit()
		return
	
	acting_enemies[0].status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func _on_enemy_statuses_applied(type: Status.Type, enemy: Enemy) -> void:
	match type:
		Status.Type.START_OF_TURN:
			enemy.do_turn()
		Status.Type.END_OF_TURN:
			acting_enemies.erase(enemy)
			_start_next_enemy_turn()


func _on_enemy_died(enemy: Enemy) -> void:
	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	
	if is_enemy_turn:
		_start_next_enemy_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()
