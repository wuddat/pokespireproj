class_name UniversalHoverTooltip
extends Control

@onready var header: RichTextLabel = %Header
@onready var description: RichTextLabel = %Description
@onready var tooltip_timer := Timer.new()

func _ready():
	tooltip_timer.wait_time = 0.4
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timeout)
	add_child(tooltip_timer)

func _on_mouse_entered():
	tooltip_timer.start()

func _on_mouse_exited():
	tooltip_timer.stop()
	TooltipManager.hide_tooltip()

func _on_tooltip_timeout():
	TooltipManager.show_tooltip(tooltip_text)
