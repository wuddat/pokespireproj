#cutscene_handler
class_name CutsceneHandler
extends CanvasLayer

const trainerscene := preload("res://scenes/animations/trainer_intro_scene.tscn")
const wildscene := preload("res://scenes/animations/wild_intro.tscn")
const mewtwo_phase_2 := preload("res://scenes/animations/mewtwo_phase_2.tscn")
const pkmn_reward_animation := preload("res://scenes/animations/pokemon_reward_animation.tscn")
@export var char_stats: CharacterStats

var current_animation: Node

func _ready() -> void:
	if not Events.mewtwo_phase_2_requested.is_connected(_on_mewtwo_phase_2_requested):
		Events.mewtwo_phase_2_requested.connect(_on_mewtwo_phase_2_requested)
	if not Events.pokemon_reward_requested.is_connected(_on_pokemon_reward_requested):
		Events.pokemon_reward_requested.connect(_on_pokemon_reward_requested)
	if not Events.pokemon_reward_completed.is_connected(_on_pokemon_reward_completed):
		Events.pokemon_reward_completed.connect(_on_pokemon_reward_completed)
	hide()

func _on_mewtwo_phase_2_requested() -> void:
	show()
	MusicPlayer.pause()
	print("transition requested")
	get_tree().paused = true
	var animation := mewtwo_phase_2.instantiate()
	add_child(animation)
	print("cutscene added")
	print("cutscene ready")
	animation.animation_player.play("dialogue")
	print("cutscene playing")
	await animation.animation_player.animation_finished
	print("cutscene complete")
	animation.queue_free()
	get_tree().paused = false
	MusicPlayer.resume()

func _on_pokemon_reward_requested(pkmn: PokemonStats) -> void:
	show()
	print("pokemon_reward cutscene added")
	get_tree().paused = true
	var animation := pkmn_reward_animation.instantiate()
	current_animation = animation
	animation.caught_pkmn = pkmn
	var new_cards: Array[Card] = char_stats.deck.cards.duplicate()
	print("new cards before: ", new_cards.size())
	new_cards = new_cards.filter(func(c): return c.pkmn_owner_uid == pkmn.uid)
	new_cards.sort_custom(func(a, b):
		if a.rarity == b.rarity:
			return a.name < b.name
		return a.rarity < b.rarity
	)
	print("pkmn_owner_uid: ", pkmn.uid)
	print("new cards after: ", new_cards.size())
	animation.cards = new_cards
	animation.char_stats = char_stats
	add_child(animation)
	print("pokemon_reward cutscene ready")
	print("cutscene playing")

func _on_pokemon_reward_completed() -> void:
	current_animation.queue_free()
	print("cutscene complete")
	get_tree().paused = false
	MusicPlayer.resume()
