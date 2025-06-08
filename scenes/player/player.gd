class_name Player
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

@export var stats: CharacterStats : set = set_character_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

#func _ready() -> void:
	#status_handler.status_owner = self
	#var exposed := preload("res://statuses/exposed.tres")
	#exposed.duration = 2
	#status_handler.add_status(exposed)

func set_character_stats(value: CharacterStats) -> void:
	stats = value
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)

	update_player()


func update_player() -> void:
	if not stats is CharacterStats:
		return
	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.art
	update_stats()


func update_stats() -> void:
	stats_ui.update_stats(stats)
