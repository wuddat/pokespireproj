class_name HealthUI 
extends HBoxContainer

@export var show_max_hp: bool
@export var bar_type: bool


@onready var block: HBoxContainer = $"../Block"
@onready var health_label: Label = %HealthLabel
@onready var max_health_label: Label = %MaxHealthLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var health_image: TextureRect = %HealthImage


func update_stats(stats: Stats) -> void:
	health_label.text = str(stats.health)
	max_health_label.text = "/%s" % str(stats.max_health)
	
	health_label.visible = !bar_type
	max_health_label.visible = !bar_type and show_max_hp
	progress_bar.visible = bar_type
	
	progress_bar.max_value = stats.max_health
	progress_bar.value = stats.health
