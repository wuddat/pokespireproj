extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")

@export var music: AudioStream
const PC_MENU_SELECT = preload("res://art/sounds/sfx/pc_menu_select.wav")

@onready var continue_button: Button = %Continue


func _ready() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)

func _on_continue_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	print("Continue run")


func _on_new_run_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	get_tree().change_scene_to_packed(CHAR_SELECTOR_SCENE)


func _on_exit_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	get_tree().quit()
