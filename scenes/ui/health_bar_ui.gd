class_name HealthBarUI
extends PanelContainer

@onready var health: HealthUI = %HealthUI
@onready var label: Label = %Label
@onready var block_label: Label = %BlockLabel
@onready var block: HBoxContainer = %Block
@onready var fainted: Label = %Fainted



func update_stats(stats: Stats) -> void:
	if block_label == null or health == null:
		await ready  # Wait until node is fully added to tree
	if block_label == null or health == null:
		push_warning("StatsUI is not fully initialized")
		return
	
	block_label.text = str(stats.block)
	
	health.update_stats(stats)
	health.health_image.visible = false
	label.text = str(stats.species_id)
	fainted.visible = stats.health <= 0
	block.visible = stats.block > 0
