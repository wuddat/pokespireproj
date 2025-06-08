class_name Battle
extends Node2D

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
@export var music: AudioStream
@export var party_selector: HBoxContainer

@onready var battle_ui: BattleUI = $BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var player: Player = $Player
@onready var party_handler: PartyHandler = $PartyHandler
@onready var pokemon_battle_unit: Node2D = $PokemonBattleUnit
@onready var left_panel: VBoxContainer = $StatUI/LeftPanel
@onready var pkmn_fainted_ui: PkmnFaintedUI = $FaintUI/PkmnFainted

var stats_ui_scn := preload("res://scenes/ui/health_bar_ui.tscn")
var stat_ui_by_uid: Dictionary = {}


func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	Events.player_pokemon_switch_completed.connect(_update_stat_ui)
	Events.player_pokemon_switch_requested.connect(_hide_switch_ui)
	
	
	
func start_battle() -> void:
	get_tree().paused = false

	battle_ui.char_stats = char_stats
	
	player.stats = char_stats
	party_handler.character_stats = char_stats
	var selected_party = party_selector.get_selected_pokemon()
	for p in selected_party:
		print("- %s | UID: %s | HP: %d" % [p.species_id, p.uid, p.health])
	party_selector.in_battle = true
	party_selector.switching = false
	party_selector.selected_switch_out_uid = ""
	party_handler.finalize_battle_party(selected_party)
	party_handler.initialize_party_for_battle()
	pkmn_fainted_ui.char_stats = char_stats
	
	update_stat_ui_for_party()
	
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	player_handler.start_battle(char_stats)
	battle_ui.initialize_card_pile_ui()

#TODO clean up this function - literally a straight copy paste chatgpt because i was tired
func update_stat_ui_for_party() -> void:
	var active_pokemon := party_handler.get_active_pokemon()
	var seen_uids: Array[String] = []

	for pkmn in char_stats.current_party:
		seen_uids.append(pkmn.uid)

		# Get or create the HealthBarUI for this Pokémon
		var ui: HealthBarUI
		if stat_ui_by_uid.has(pkmn.uid):
			ui = stat_ui_by_uid[pkmn.uid]
		else:
			ui = stats_ui_scn.instantiate()
			left_panel.add_child(ui)
			stat_ui_by_uid[pkmn.uid] = ui

		# Always update stats immediately
		ui.update_stats(pkmn)

		# Connect if not already connected
		if not pkmn.stats_changed.is_connected(_update_pokemon_stats_ui):
			pkmn.stats_changed.connect(_update_pokemon_stats_ui.bind(pkmn, ui))

		# Hide by default
		ui.visible = true
		ui.modulate = Color(1,1,1,.5)

	# Reveal only the UIs for currently active Pokémon
	for pkmn in active_pokemon:
		if stat_ui_by_uid.has(pkmn.uid):
			stat_ui_by_uid[pkmn.uid].visible = true
			var ui = stat_ui_by_uid[pkmn.uid]
			ui.modulate = Color(1,1,1,1)

	# Clean up orphaned bars
	for uid in stat_ui_by_uid.keys():
		if not seen_uids.has(uid):
			stat_ui_by_uid[uid].queue_free()
			stat_ui_by_uid.erase(uid)




func _update_pokemon_stats_ui(pkmn: PokemonStats, ui: HealthBarUI) -> void:
	ui.update_stats(pkmn)



func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0:
		MusicPlayer.play(music, true)
		Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()
	
	
func _on_player_died() -> void:
		Events.battle_over_screen_requested.emit("You Whited Out!", BattleOverPanel.Type.LOSE)


func _update_stat_ui(pkmn: PokemonStats) -> void:
	if stat_ui_by_uid.has(pkmn.uid):
		var ui = stat_ui_by_uid[pkmn.uid]
		ui.update_stats(pkmn)
		ui.modulate = Color(1,1,1,1)
		if not pkmn.stats_changed.is_connected(_update_pokemon_stats_ui):
			pkmn.stats_changed.connect(_update_pokemon_stats_ui.bind(pkmn, stat_ui_by_uid[pkmn.uid]))
		_update_pokemon_stats_ui(pkmn, ui)

func _hide_switch_ui(switch_out_uid: String, switch_in_uid: String) -> void:
	if stat_ui_by_uid.has(switch_out_uid):
		var ui = stat_ui_by_uid[switch_out_uid]
		ui.modulate = Color(1,1,1,.5)
