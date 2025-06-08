class_name StatsUI
extends HBoxContainer

@onready var block: HBoxContainer = $Block
@onready var block_label: Label = %BlockLabel
@onready var health: HealthUI = %Health


#func _ready() -> void:
	#if not Events.player_pokemon_switch_completed.is_connected(_on_pokemon_switch):
		#Events.player_pokemon_switch_completed.connect(_on_pokemon_switch)

func update_stats(stats: Stats) -> void:
	if block_label == null or health == null:
		await ready  # Wait until node is fully added to tree
	if block_label == null or health == null:
		push_warning("StatsUI is not fully initialized")
		return
	
	block_label.text = str(stats.block)
	health.update_stats(stats)

	block.visible = stats.block > 0
	health.visible = stats.health > 0

#func _on_pokemon_switch() -> void:
	#update_stats()
