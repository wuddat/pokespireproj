#battle.gd
class_name Battle
extends Node2D

signal evolution_queue_completed

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
@export var music: AudioStream
@export var battle_music: AudioStream
@export var party_selector: HBoxContainer
@export var party_view: PartyView
@onready var status_view: StatusView = $StatusUI/StatusView
@onready var background: Sprite2D = %Background
@onready var background_2: Sprite2D = %Background2

@onready var battle_ui: BattleUI = $BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var player: Player = $Player
@onready var party_handler: PartyHandler = $PartyHandler
@onready var left_panel: VBoxContainer = $StatUI/LeftPanel
@onready var pkmn_fainted_ui: PkmnFaintedUI = $FaintUI/PkmnFainted


var stats_ui_scn := preload("res://scenes/ui/health_bar_ui.tscn")
var stat_ui_by_uid: Dictionary = {}

var evolution_in_progress := false
var evolution_queue: Array[PokemonBattleUnit] = []
var is_processing_evolution := false


func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	print("✅ Connected enemy_handler.child_order_changed!")
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	Events.player_pokemon_switch_completed.connect(_update_stat_ui)
	Events.player_pokemon_switch_requested.connect(_hide_switch_ui)
	Events.party_pokemon_fainted.connect(_on_party_pokemon_fainted)
	Events.evolution_triggered.connect(_on_evolution_triggered)
	Events.evolution_completed.connect(_on_evolution_completed)
	Events.mewtwo_phase_2_requested.connect(_on_mewtwo_phase_2_requested)


func start_battle() -> void:
	get_tree().paused = false
	background.show()
	background_2.hide()
	status_view.visible = true
	battle_ui.char_stats = char_stats
	battle_ui.party_view = party_view
	
	player.stats = char_stats
	
	for pkmn in char_stats.current_party:
		pkmn.leveled_up_in_battle = false
	
	party_handler.character_stats = char_stats
	var selected_party = party_selector.get_selected_pokemon()
	for p in selected_party:
		print("- %s | UID: %s | HP: %d" % [p.species_id, p.uid, p.health])
	party_selector.in_battle = true
	party_selector.switching = false
	party_selector.selected_switch_out_uid = ""
	party_handler.stat_ui_by_uid = stat_ui_by_uid  
	party_handler.finalize_battle_party(selected_party)
	party_handler.initialize_party_for_battle()
	
	pkmn_fainted_ui.char_stats = char_stats
	
	initialize_stat_ui_for_party()
	
	enemy_handler.char_stats = char_stats
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	player_handler.start_battle(char_stats)
	battle_ui.initialize_card_pile_ui()


func initialize_stat_ui_for_party() -> void:
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
	if not is_instance_valid(get_tree()):
		return
	await get_tree().create_timer(1).timeout
	
	if enemy_handler.get_child_count() == 0:
		if is_processing_evolution or evolution_queue.size() > 0:
			print("🕐 Waiting for evolution queue to finish...")
			await evolution_queue_completed
			
		MusicPlayer.play(music, true)
		
		Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	#removed await - return if crash
	enemy_handler.reset_enemy_actions()


func _on_player_died() -> void:
		Events.battle_over_screen_requested.emit("You Whited Out!", BattleOverPanel.Type.LOSE)
		SaveData.delete_data()


func _update_stat_ui(pkmn: PokemonStats) -> void:
	if stat_ui_by_uid.has(pkmn.uid):
		var ui = stat_ui_by_uid[pkmn.uid]
		ui.update_stats(pkmn)
		ui.modulate = Color(1,1,1,1)
		if not pkmn.stats_changed.is_connected(_update_pokemon_stats_ui):
			pkmn.stats_changed.connect(_update_pokemon_stats_ui.bind(pkmn, stat_ui_by_uid[pkmn.uid]))
		_update_pokemon_stats_ui(pkmn, ui)


func _hide_switch_ui(switch_out_uid: String, _switch_in_uid: String) -> void:
	if stat_ui_by_uid.has(switch_out_uid):
		var ui = stat_ui_by_uid[switch_out_uid]
		ui.modulate = Color(1,1,1,.5)


func _on_party_pokemon_fainted(pkmn: PokemonBattleUnit):
	if pkmn and pkmn.is_inside_tree():
		pkmn.status_handler.clear_all_statuses()
	var fainted_pkmn = 0
	print("char stats:", char_stats)
	print("char_stats_size: ", char_stats.current_party.size())
	for poke in char_stats.current_party:
		print(poke.species_id)
	for poke in char_stats.current_party:
		if poke.health <= 0:
			fainted_pkmn += 1
			print("Fainted pkmn: %s / %s" % [fainted_pkmn, char_stats.current_party.size()])
	if fainted_pkmn == char_stats.current_party.size():
		Events.player_died.emit()


func _on_evolution_triggered(pkmn: PokemonBattleUnit) -> void:
	if not is_instance_valid(pkmn): return
	evolution_queue.append(pkmn)
	
	if not is_processing_evolution:
			_process_evolution_queue()


func _process_evolution_queue() -> void:
	is_processing_evolution = true
	
	while evolution_queue.size() > 0:
		var pkmn = evolution_queue.pop_front()
		evolution_in_progress = true
		await _play_evolution_cutscene(pkmn)
		evolution_in_progress = false
		Events.evolution_completed.emit()
		await get_tree().create_timer(0.5).timeout
	is_processing_evolution = false
	evolution_queue_completed.emit()


func _on_evolution_completed():
	evolution_in_progress = false
	_on_enemies_child_order_changed()


func _play_evolution_cutscene(pkmn: PokemonBattleUnit) -> void:
	print("pausing tree....")
	get_tree().paused = true
	print("loading animation...")
	var evo_scene := preload("res://scenes/ui/evolution_animation.tscn").instantiate()
	var evolved_species := pkmn.stats.get_evolved_species_id()
	print("getting species id...")
	print("id: ",evolved_species)
	get_tree().root.add_child(evo_scene)
	await get_tree().process_frame
	
	evo_scene.setup(pkmn.stats.species_id, evolved_species, pkmn.global_position)
	pkmn.hide()
	
	await evo_scene.animation_completed
	
	pkmn.stats.evolve_to(evolved_species)
	pkmn.update_pokemon()
	char_stats.update_draftable_cards()
	pkmn.show()
	# 🎁 Inject EvolutionReward Screen
	var evo_reward := preload("res://scenes/ui/evolution_rewards.tscn").instantiate()
	$BattleOverLayer.add_child(evo_reward)
	var _evo_card_rewards: Array[Card] = []
	var forgettable_cards: Array[Card] = char_stats.deck.cards.duplicate(true)
	var learnable_cards: Array[Card] = char_stats.draftable_cards.cards.duplicate(true)
	
	forgettable_cards = forgettable_cards.filter(
		func(card: Card) -> bool:
			return card.pkmn_owner_uid == pkmn.stats.uid and card.rarity == Card.Rarity.COMMON
	)

	learnable_cards = learnable_cards.filter(
		func(card: Card) -> bool:
			return card.pkmn_owner_uid == pkmn.stats.uid and (
				card.rarity == Card.Rarity.UNCOMMON or card.rarity == Card.Rarity.RARE
			)
	)
	
	RNG.array_shuffle(learnable_cards)
	RNG.array_shuffle(forgettable_cards)
	learnable_cards = learnable_cards.slice(0, 3)
	forgettable_cards = forgettable_cards.slice(0, 3)

	evo_reward.player_deck = char_stats.deck
	evo_reward.pokemon = pkmn.stats
	evo_reward.sprite_2d.texture= pkmn.stats.art
	evo_reward.label.text = "%s wants to learn a NEW move!" % pkmn.stats.species_id.capitalize()
	evo_reward.forgettable_cards = forgettable_cards
	evo_reward.learnable_cards = learnable_cards

	# Wait for reward to finish before resuming battle
	await evo_reward.tree_exited
	
	get_tree().paused = false


func _on_mewtwo_phase_2_requested() -> void:
	background.hide()
	background_2.show()
