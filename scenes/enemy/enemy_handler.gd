#enemy_handler.gd
class_name EnemyHandler
extends Node2D

@onready var right_panel: VBoxContainer = $"../StatUI/RightPanel"
@onready var party_handler: PartyHandler = $"../PartyHandler"

var stats_ui_scn := preload("res://scenes/ui/health_bar_ui.tscn")
var acting_enemies: Array[Enemy] = []
var caught_pokemon: Array[PokemonStats] = []

var enemy_text_delay: float = 0.4

func _ready() -> void:
	Events.enemy_fainted.connect(_on_enemy_fainted)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.player_hand_discarded.connect(_on_player_hand_drawn)
	Events.pokemon_captured.connect(_on_pokemon_captured)
	Events.party_pokemon_fainted.connect(_on_party_pokemon_fainted)

func setup_enemies(battle_stats: BattleStats) -> void:
	if not battle_stats:
		return
	
	for enemy: Enemy in get_children():
		enemy.queue_free()
	
	var all_new_enemies := battle_stats.enemies.instantiate()
	var species_ids = Pokedex.get_species_for_tier(battle_stats.battle_tier)
	
	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		var random_species := species_ids.pick_random() as String
		
		var new_stats := preload("res://enemies/generic_enemy/generic_enemy.tres").duplicate()
		new_stats.species_id = random_species
		new_enemy_child.stats = new_stats
		
		add_child(new_enemy_child)
		
		var ui := stats_ui_scn.instantiate() as HealthBarUI

		
		right_panel.add_child(ui)
		ui.icon.position = Vector2(60,7)
		
		ui.update_stats(new_enemy_child.stats)

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
	
	var battling_pokemon := party_handler.get_active_pokemon_nodes()
	if battling_pokemon:
		for battler in battling_pokemon:
			if battler.has_method("on_enemy_defeated"):
				battler.on_enemy_defeated(enemy)
	
	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	
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
