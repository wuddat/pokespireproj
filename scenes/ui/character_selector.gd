extends Control

const RUN_SCENE = preload("res://scenes/run/run.tscn")
const BULBASAUR_STATS := preload("res://characters/bulbasaur/bulbasaur.tres")
const SQUIRTLE_STATS := preload("res://characters/squirtle.tres")
const CHARMANDER_STATS := preload("res://characters/charmander.tres")

@export var run_startup: RunStartup

@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var character_portrait: AnimatedSprite2D = %CharacterPortrait


var current_character: CharacterStats : set = set_current_character


func _ready() -> void:
	set_current_character(BULBASAUR_STATS)


func set_current_character(new_charcter: CharacterStats) -> void:
	current_character = new_charcter
	title.text = current_character.character_name
	description.text = current_character.description
	character_portrait.sprite_frames = current_character.frames
	character_portrait.play()

func _on_start_button_pressed() -> void:
	#print("Start new Run with %s" % current_character.character_name)
	run_startup.type = RunStartup.Type.NEW_RUN
	run_startup.picked_character = current_character
	get_tree().change_scene_to_packed(RUN_SCENE)

func _on_bulbasaur_button_pressed() -> void:
	current_character = BULBASAUR_STATS

func _on_squirtle_button_pressed() -> void:
	current_character = SQUIRTLE_STATS


func _on_charmander_button_pressed() -> void:
	current_character = CHARMANDER_STATS
