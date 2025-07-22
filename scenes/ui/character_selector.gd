extends Control

const RUN_SCENE = preload("res://scenes/run/run.tscn")
const BULBASAUR_STATS := preload("res://characters/bulbasaur/bulbasaur.tres")
const SQUIRTLE_STATS := preload("res://characters/squirtle.tres")
const CHARMANDER_STATS := preload("res://characters/charmander.tres")
const PC_MENU_SELECT = preload("res://art/sounds/sfx/pc_menu_select.wav")

@export var run_startup: RunStartup

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var character_portrait: AnimatedSprite2D = %CharacterPortrait
@onready var character_text: VBoxContainer = $CharacterText


var current_character: CharacterStats : set = set_current_character
var tween: Tween
var active_button: String = "bulbasaur"
var starting_portrait_pos: Vector2
var starting_title_pos: Vector2

func _ready() -> void:
	set_current_character(BULBASAUR_STATS)
	starting_portrait_pos = character_portrait.global_position
	starting_title_pos = character_text.global_position


func set_current_character(new_charcter: CharacterStats) -> void:
	SFXPlayer.play(PC_MENU_SELECT)
	current_character = new_charcter
	title.text = current_character.character_name
	description.text = current_character.description
	character_portrait.sprite_frames = current_character.frames
	character_portrait.play()

func _on_start_button_pressed() -> void:
	#print("Start new Run with %s" % current_character.character_name)
	SFXPlayer.play(PC_MENU_SELECT)
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.picked_character = current_character
	get_tree().change_scene_to_packed(RUN_SCENE)

func _on_bulbasaur_button_pressed() -> void:
	if active_button != "bulbasaur":
		if tween and tween.is_running():
			tween.kill()
		SFXPlayer.play(PC_MENU_SELECT)
		active_button = "bulbasaur"
		_tween_on_select()
	

func _on_squirtle_button_pressed() -> void:
	if active_button != "squirtle":
		if tween and tween.is_running():
			tween.kill()
		SFXPlayer.play(PC_MENU_SELECT)
		active_button = "squirtle"
		_tween_on_select()
		


func _on_charmander_button_pressed() -> void:
	if active_button != "charmander":
		if tween and tween.is_running():
			tween.kill()
		SFXPlayer.play(PC_MENU_SELECT)
		active_button = "charmander"
		_tween_on_select()
		


func _tween_on_select() -> void:
		tween = create_tween()
		tween.tween_property(character_portrait, "global_position", Vector2(character_portrait.global_position.x-800,character_portrait.global_position.y), 0.2)
		tween.parallel().tween_property(character_text, "global_position", Vector2(character_text.global_position.x+800,character_text.global_position.y), 0.2)
		await tween.finished
		if active_button == "charmander":
			current_character = CHARMANDER_STATS
		if active_button == "bulbasaur":
			current_character = BULBASAUR_STATS
		if active_button == "squirtle":
			current_character = SQUIRTLE_STATS
		tween = create_tween()
		tween.tween_property(character_portrait, "global_position", Vector2(starting_portrait_pos), 0.2)
		tween.parallel().tween_property(character_text, "global_position", Vector2(starting_title_pos), 0.2)
