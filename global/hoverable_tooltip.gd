#hoverable_tooltip.gd
extends Control

var universal_hover_tooltip: Control

@export var use_provider := true

var tooltip_timer := Timer.new()
var resolved_header_text := ""
var resolved_description_text := ""

func _ready():
	tooltip_timer.wait_time = 0.4
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timeout)
	universal_hover_tooltip = get_tree().get_root().get_node("Run/SceneTransition/UniversalHoverTooltip")
	add_child(tooltip_timer)

	if has_signal("mouse_entered"):
		connect("mouse_entered", _on_mouse_entered)
	if has_signal("mouse_exited"):
		connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	tooltip_timer.start()
	print("entered tooltip area")

func _on_mouse_exited():
	tooltip_timer.stop()
	universal_hover_tooltip.hide_tooltip()
	print("exited tooltip area")


func _on_tooltip_timeout():
	var header := ""
	var description := ""

	if use_provider and owner.has_method("get_tooltip_data"):
		var data = owner.get_tooltip_data()
		header = data.get("header", "")
		description = data.get("description", "")
	else:
		header = "Replace me"
		description = "No tooltip data available"

	universal_hover_tooltip.show_tooltip(header, description)
