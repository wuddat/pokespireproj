class_name PokemonBattleUnit
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

@export var stats: PokemonStats : set = set_pokemon_stats
@export var spawn_position: String

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler


func _ready() -> void:
	status_handler.status_owner = self
	status_handler.statuses_applied.connect(_on_statuses_applied)


func start_of_turn():
	stats.block = 0
	status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func set_pokemon_stats(value: PokemonStats) -> void:
	stats = value

	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)

	update_pokemon()

func update_pokemon() -> void:
	if not stats is PokemonStats:
		print("Invalid stats on PokémonBattleUnit")
		return
	if not is_inside_tree():
		await ready
		
	print("Updating Pokémon: %s with HP %d" % [stats.species_id, stats.health])
	sprite_2d.texture = stats.art
	update_stats()

func update_stats() -> void:
	stats_ui.update_stats(stats)

func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return

	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)

	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 25, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)

	tween.finished.connect(func():
		sprite_2d.material = null
		if stats.health <= 0:
			Events.party_pokemon_fainted.emit(self)
			queue_free()
	)


func _on_statuses_applied(type: Status.Type) -> void:
	if type == Status.Type.START_OF_TURN:
		Events.player_pokemon_start_status_applied.emit(self)
	elif type == Status.Type.END_OF_TURN:
		Events.player_pokemon_end_status_applied.emit(self)
