extends Control

@onready var header: RichTextLabel = %Header
@onready var description: RichTextLabel = %Description
@onready var container: PanelContainer = $Container
var fade_tween: Tween

var offset := Vector2(6, -30)
const MARGIN := 25

func _process(_delta):
	if visible:
		var mouse_pos := get_viewport().get_mouse_position()
		var viewport_size := get_viewport_rect().size
		var tooltip_size := container.size
		var new_pos := mouse_pos + offset

		# Flip horizontally if overflowing right
		if new_pos.x + tooltip_size.x + MARGIN > viewport_size.x:
			new_pos.x = mouse_pos.x - tooltip_size.x - abs(offset.x)
		
		## Flip vertically if overflowing bottom
		#if new_pos.y + tooltip_size.y + MARGIN > viewport_size.y:
			#new_pos.y = mouse_pos.y - tooltip_size.y - abs(offset.y)

		# Clamp to edges with margin
		new_pos.x = clamp(new_pos.x, MARGIN, viewport_size.x - tooltip_size.x - MARGIN)
		new_pos.y = clamp(new_pos.y, MARGIN, viewport_size.y - tooltip_size.y - MARGIN)

		position = new_pos


func show_tooltip(header_text: String, description_text: String):
	if not header or not description:
		push_error("Tooltip was used before it was set up.")
		return
	header.text = header_text
	description.text = description_text
	fade_in()

func hide_tooltip():
	fade_out()


func fade_in(duration := 0.1) -> void:
	show()
	self.modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, duration)
	await fade_tween.finished


func fade_out(duration := 0.1) -> void:
	show()
	self.modulate.a = 1.0
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, duration)
	await fade_tween.finished
