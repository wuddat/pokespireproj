class_name Pokecenter
extends Control

@export var char_stats: CharacterStats

@onready var rest_button: Button = $UILayer/UI/RestButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const music = preload("res://art/music/PokemonCenter.mp3")
const recovery = preload("res://art/music/23 Pokemon Recovery.mp3")

func _ready() -> void:
	MusicPlayer.play(music, true)
	

func _on_rest_button_pressed() -> void:
	MusicPlayer.play(recovery, true)
	rest_button.visible = false
	char_stats.heal(char_stats.max_health)
	for pkmn in char_stats.current_party:
		pkmn.health = pkmn.max_health
	animation_player.play("fade_out")

#this is called from the AnimationPlayer as 'fade-out' in Pkmncentr scene
func _on_fadeout_finished() -> void:
	Events.pokecenter_exited.emit()
