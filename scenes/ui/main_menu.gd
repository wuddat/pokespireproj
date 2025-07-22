extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE := preload("res://scenes/run/run.tscn")

@export var run_startup: RunStartup
@export var music: AudioStream

const PC_MENU_SELECT = preload("res://art/sounds/sfx/pc_menu_select.wav")

@onready var continue_button: Button = %Continue


func _ready() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)
	
	continue_button.disabled = SaveData.load_data() == null

func _on_continue_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_run_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	get_tree().change_scene_to_packed(CHAR_SELECTOR_SCENE)


func _on_exit_pressed() -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	get_tree().quit()
