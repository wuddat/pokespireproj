class_name GoldUI
extends HBoxContainer

@export var run_stats: RunStats : set = set_run_stats

@onready var hoverable_tooltip: Control = $Icon/HoverableTooltip
@onready var label: Label = $Label


func _ready() -> void:
	label.text = "0"
	
	
func set_run_stats(new_vcalue: RunStats) -> void:
	run_stats = new_vcalue
	
	if not run_stats.gold_changed.is_connected(_update_gold):
		run_stats.gold_changed.connect(_update_gold)
		_update_gold()


func _update_gold() -> void:
	label.text =str(run_stats.gold)


func get_tooltip_data() -> Dictionary:
	var intent_description: String = ""
	return {
		"header": "[color=goldenrod]Gold[/color]:",
		"description": "used  to  buy  stuff!"
	}
