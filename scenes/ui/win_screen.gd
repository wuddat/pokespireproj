#win_screen.gd
class_name WinScreen
extends Control

const MAIN_MENU = "res://scenes/ui/main_menu.tscn"
const PKMN_BUTTON = preload("res://scenes/ui/pkmn_button.tscn")
const PC_MENU_SELECT = preload("res://art/sounds/sfx/pc_menu_select.wav")

@onready var pkmn_display: HBoxContainer = %PkmnDisplay

@export var char_stats: CharacterStats : set = set_character
@export var music: AudioStream


func _ready() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)


func set_character(new_char_stats: CharacterStats) -> void:
	char_stats = new_char_stats
	for pkmn in char_stats.current_party:
		var pkmn_btn = PKMN_BUTTON.instantiate() as PkmnButton
		pkmn_btn.texture_normal = pkmn.art
		pkmn_btn.name_label = pkmn.species_id.capitalize()
		pkmn_display.add_child(pkmn_btn)


func _on_main_menu_button_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	get_tree().change_scene_to_file(MAIN_MENU)
