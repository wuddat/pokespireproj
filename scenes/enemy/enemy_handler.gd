class_name EnemyHandler
extends Node2D


func _ready() -> void:
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


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
	
	var first_enemy: Enemy = get_child(0) as Enemy
	first_enemy.do_turn()
	
	
func _on_enemy_action_completed(enemy: Enemy) -> void:
	if enemy.get_index() == get_child_count() -1:
		Events.enemy_turn_ended.emit()
		return
	
	var next_enemy: Enemy = get_child(enemy.get_index() + 1) as Enemy
	next_enemy.do_turn()
