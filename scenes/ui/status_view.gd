class_name StatusView
extends Control

@export var fade_seconds := 0.2

@onready var status_tooltips: VBoxContainer = %StatusTooltips

var tween: Tween
var is_visible := false

const STATUS_TOOLTIP = preload("res://scenes/ui/status_tooltip.tscn")

func _ready() -> void:
	for tooltip: StatusTooltip in status_tooltips.get_children():
		tooltip.queue_free()
	
	Events.status_tooltip_hide_requested.connect(hide_tooltip)
	Events.status_tooltip_requested.connect(show_tooltip)
	modulate = Color.TRANSPARENT
	hide()


func show_tooltip(statuses: Array[Status]) -> void:
	is_visible = true
	if tween:
		tween.kill()
		
	for status: Status in statuses:
		var new_status_tooltip := STATUS_TOOLTIP.instantiate() as StatusTooltip
		status_tooltips.add_child(new_status_tooltip)
		new_status_tooltip.status = status
		
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(show)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)


func hide_tooltip() -> void:
	is_visible = false
	if tween:
		tween.kill()
	
	for tooltip: StatusTooltip in status_tooltips.get_children():
		tooltip.queue_free()
		
	get_tree().create_timer(fade_seconds, false).timeout.connect(hide_animation)


func hide_animation() -> void:
	if not is_visible:
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
		tween.tween_callback(hide)
