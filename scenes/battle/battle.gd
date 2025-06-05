class_name Battle
extends Node2D

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
@export var music: AudioStream

@onready var battle_ui: BattleUI = $BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var player: Player = $Player
@onready var party_handler: PartyHandler = $PartyHandler
@onready var pokemon_battle_unit: Node2D = $PokemonBattleUnit
@onready var left_panel: VBoxContainer = $StatUI/LeftPanel

var stats_ui_scn := preload("res://scenes/ui/health_bar_ui.tscn")

func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	
	
func start_battle() -> void:
	get_tree().paused = false

	battle_ui.char_stats = char_stats
	
	player.stats = char_stats
	party_handler.character_stats = char_stats
	party_handler.initialize_party_for_battle()
	
	display_active_party_ui()
	
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	player_handler.start_battle(char_stats)
	battle_ui.initialize_card_pile_ui()


func display_active_party_ui()-> void:
	var actives := party_handler.get_active_pokemon()

	for pkmn_stats in actives:
		var ui := stats_ui_scn.instantiate() as HealthBarUI
		
		left_panel.add_child(ui)
		
		ui.update_stats(pkmn_stats)
		print("Added StatsUI for", pkmn_stats.species_id)
		print("Parent node:", ui.get_parent())

		if not pkmn_stats.stats_changed.is_connected(ui.update_stats):
			pkmn_stats.stats_changed.connect(func(): ui.update_stats(pkmn_stats))


func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0:
		MusicPlayer.play(music, true)
		Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()
	
	
func _on_player_died() -> void:
		Events.battle_over_screen_requested.emit("You Whited Out!", BattleOverPanel.Type.LOSE)
