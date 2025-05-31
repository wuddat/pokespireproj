class_name Run
extends Node

const battlescene := preload("res://scenes/battle/battle.tscn")
const rewardscene := preload("res://scenes/battle_reward/battle_reward.tscn")
const pokecenterscene := preload("res://scenes/pokecenter/pokecenter.tscn")
const mapscene := preload("res://scenes/map/map.tscn")
const shopscene := preload("res://scenes/shop/shop.tscn")
const treasurescene := preload("res://scenes/treasure/treasure.tscn")

@export var run_startup: RunStartup

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

var stats: RunStats
var character: CharacterStats


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
	print("TODO: procedurally generate map")


func _change_view(scene: PackedScene) -> Node:
	if currentview.get_child_count() > 0:
		currentview.get_child(0).queue_free()
	
	get_tree().paused = false
	var new_view := scene.instantiate()
	currentview.add_child(new_view)
	
	return new_view


func _setup_event_connections() -> void:
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_change_view.bind(mapscene))
	Events.pokecenter_exited.connect(_change_view.bind(mapscene))
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_change_view.bind(mapscene))
	Events.treasure_room_exited.connect(_change_view.bind(mapscene))
	
	battlebutton.pressed.connect(_change_view.bind(battlescene))
	pokecenterbtn.pressed.connect(_change_view.bind(pokecenterscene))
	mapbtn.pressed.connect(_change_view.bind(mapscene))
	rewardsbtn.pressed.connect(_change_view.bind(rewardscene))
	shopbtn.pressed.connect(_change_view.bind(shopscene))
	treasurebtn.pressed.connect(_change_view.bind(treasurescene))


func 	_setup_top_bar():
	gold_ui.run_stats = stats
	deck_button.card_pile = character.deck
	deck_view.card_pile = character.deck
	deck_button.pressed.connect(deck_view.show_current_view.bind("Deck"))


func _on_battle_won() -> void:
	var reward_scene := _change_view(rewardscene) as BattleReward
	reward_scene.run_stats = stats
	reward_scene.character_stats = character

#	This is temporary, it will come from actual battle encounter as a dep l8r
	reward_scene.add_gold_reward(211)
	reward_scene.add_card_reward()

func _on_map_exited() -> void:
	print("TODO: from the map, change view based on selected room")
