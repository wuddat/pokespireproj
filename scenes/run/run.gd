#run.gd
class_name Run
extends Node

const battlescene := preload("res://scenes/battle/battle.tscn")
const rewardscene := preload("res://scenes/battle_reward/battle_reward.tscn")
const pokecenterscene := preload("res://scenes/pokecenter/pokecenter.tscn")
const shopscene := preload("res://scenes/shop/shop.tscn")
const treasurescene := preload("res://scenes/treasure/treasure.tscn")
const eventscene := preload("res://scenes/event/event.tscn")
const trainerscene := preload("res://scenes/animations/trainer_intro_scene.tscn")
const wildscene := preload("res://scenes/animations/wild_intro.tscn")
const universalhovertooltip := preload("res://scenes/ui/universal_hover_tooltip.tscn")
@export var run_startup: RunStartup

@onready var map: Map = $Map
@onready var currentview: Node = $CurrentView
@onready var gold_ui: GoldUI = %GoldUI
@onready var deck_button: CardPileOpener = %DeckButton
@onready var deck_view: CardPileView = %DeckView

@onready var battlebutton: Button = %BattleButton
@onready var pokecenterbtn: Button = %PokecenterButton
@onready var mapbtn: Button = %MapButton
@onready var rewardsbtn: Button = %RewardsButton
@onready var shopbtn: Button = %ShopButton
@onready var treasurebtn: Button = %TreasureButton
@onready var health_ui: HealthUI = %HealthUI
@onready var party_selector: HBoxContainer = %PartySelector
@onready var fade: ColorRect = %Fade
@onready var fade_tween := create_tween()
@onready var particles: CanvasLayer = %Particles


var stats: RunStats
var character: CharacterStats
var caught_pokemon: Array[PokemonStats] = []
var leveled_in_battle_pkmn: Array[PokemonStats] = []


func _ready() -> void:
	if not run_startup:
		return
		
	match run_startup.type:
		RunStartup.Type.NEW_RUN:
			character = run_startup.picked_character.create_instance()
			_start_run()
		RunStartup.Type.CONTINUED_RUN:
			print("TODO: load previous run")


func _start_run() -> void:
	stats = RunStats.new()
	
	_setup_event_connections()
	_setup_top_bar()
	
	map.generate_new_map()
	map.unlock_floor(0)


func _change_view(scene: PackedScene) -> Node:
	if currentview.get_child_count() > 0:
		currentview.get_child(0).queue_free()
	
	get_tree().paused = false
	var new_view := scene.instantiate()
	currentview.add_child(new_view)
	map.hide_map()
	particles.hide()
	return new_view


func _show_map() -> void:
	if currentview.get_child_count() > 0:
		currentview.get_child(0).queue_free()
		
	map.show_map()
	map.unlock_next_rooms()
	particles.show()
	


func _setup_event_connections() -> void:
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_show_map)
	Events.pokecenter_exited.connect(_show_map)
	Events.event_room_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_show_map)
	Events.pokemon_captured.connect(_on_pokemon_captured)
	Events.added_pkmn_to_party.connect(_update_party_buttons)
	Events.added_pkmn_to_party.connect(_update_draftable_cards)
	Events.party_pokemon_fainted.connect(_update_draftable_cards)
	Events.party_pokemon_fainted.connect(_update_party_buttons)
	Events.evolution_completed.connect(_on_evolution_completed)
	Events.add_leveled_pkmn_to_rewards.connect(_on_leveled_pkmn_to_rewards)
	Events.return_to_main_menu.connect(_on_return_to_main_menu)
	
	battlebutton.pressed.connect(_change_view.bind(battlescene))
	pokecenterbtn.pressed.connect(_change_view.bind(pokecenterscene))
	mapbtn.pressed.connect(_show_map)
	rewardsbtn.pressed.connect(_change_view.bind(rewardscene))
	shopbtn.pressed.connect(_change_view.bind(shopscene))
	treasurebtn.pressed.connect(_change_view.bind(treasurescene))


func 	_setup_top_bar():
	character.stats_changed.connect(health_ui.update_stats.bind(character))
	health_ui.update_stats(character)
	gold_ui.run_stats = stats
	deck_button.card_pile = character.deck
	deck_button.container_name = "Deck"
	deck_view.card_pile = character.deck
	deck_view.char_stats = character
	deck_button.pressed.connect(deck_view.show_current_view.bind("Deck", true))
	party_selector.char_stats = character
	party_selector.update_buttons()


func fade_in(duration := 0.5) -> void:
	fade.visible = true
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 0.0, duration)
	await fade_tween.finished
	fade.visible = false


func fade_out(duration := 0.5) -> void:
	fade.visible = true
	fade.modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "modulate:a", 1.0, duration)
	await fade_tween.finished

func _load_battle(room :Room) ->void:
	caught_pokemon.clear() 
	leveled_in_battle_pkmn.clear()
	var battle_scene: Battle = _change_view(battlescene) as Battle
	battle_scene.char_stats = character
	battle_scene.party_selector = party_selector
	battle_scene.battle_stats = room.battle_stats
	battle_scene.start_battle()
	party_selector.in_battle = true

func _on_battle_room_entered(room: Room) -> void:
	var animation := wildscene.instantiate()
	add_child(animation)
	#animation.global_position = get_viewport().get_visible_rect().size / 2
	await animation.play_intro()
	_load_battle(room)
	await fade_in()

func _on_trainer_room_entered(room: Room) -> void:
	var animation := trainerscene.instantiate()
	add_child(animation)
	#animation.global_position = get_viewport().get_visible_rect().size / 2
	animation.sprite_2d.texture = room.battle_stats.trainer_sprite
	animation.trainer_name.text = room.battle_stats.trainer_type
	await animation.play_intro()
	_load_battle(room)
	await fade_in()
	
func _on_shop_entered() -> void:
	await fade_out()
	var shop  := _change_view(shopscene) as Shop
	shop.char_stats = character
	shop.run_stats = stats
	shop.populate_shop()
	await fade_in()


func _on_pokecenter_entered() -> void:
	await fade_out()
	var pokecenter_scene: Pokecenter = _change_view(pokecenterscene) as Pokecenter
	pokecenter_scene.char_stats = character
	await fade_in()

func _on_event_entered() -> void:
	await fade_out()
	var scene := _change_view(eventscene) as EventScene
	scene.char_stats = character
	scene.run_stats = stats
	await fade_in()


func _on_battle_won() -> void:
	var reward_scene := _change_view(rewardscene) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character
	reward_scene.caught_pokemon = caught_pokemon
	reward_scene.leveled_pkmn_in_battle = leveled_in_battle_pkmn
	print("caught pokemon in _on_battle_won: ", caught_pokemon)
	for pkmn in caught_pokemon:
		print(pkmn.species_id)
		
	reward_scene.gold_reward = (map.last_room.battle_stats.roll_gold_reward())
	reward_scene._play_reward_sequence()
	party_selector.in_battle = false

func _on_map_exited(room: Room) -> void:
	match room.type:
		Room.Type.MONSTER:
			_on_battle_room_entered(room)
		Room.Type.TREASURE:
			_change_view(treasurescene)
		Room.Type.POKECENTER:
			_on_pokecenter_entered()
		Room.Type.SHOP:
			_on_shop_entered()
		Room.Type.BOSS:
			_on_battle_room_entered(room)
		Room.Type.EVENT:
			_on_event_entered()
		Room.Type.TRAINER:
			_on_trainer_room_entered(room)


func _on_pokemon_captured(stats: PokemonStats) -> void:
	caught_pokemon.append(stats.duplicate())
	print("caught pokemon in run: ", caught_pokemon)


func _update_party_buttons() -> void:
	party_selector.char_stats = character
	party_selector.update_buttons()
	
	character.check_if_all_party_fainted()


func _update_draftable_cards(pkmn: PokemonStats) -> void:
	character.on_added_pkmn_to_party(pkmn)
	character.update_draftable_cards()

func _on_evolution_completed() -> void:
	character.update_draftable_cards()

func _on_leveled_pkmn_to_rewards(pkmn: PokemonStats) -> void:
	leveled_in_battle_pkmn.append(pkmn)

func _on_return_to_main_menu() -> void:
	await get_tree().create_timer(0.1).timeout  # Let current frame/signal stack finish
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
