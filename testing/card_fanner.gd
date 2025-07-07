class_name CardFanner
extends CenterContainer

@export var card: Card
@onready var fan_layer := Control.new()
@export var matches: int
@onready var area_2d: Area2D = $Area2D

const SUPER_DETAIL_UI = preload("res://scenes/ui/card_super_detail_ui.tscn")

const FAN_SPACING := 30.0
const FAN_SCALE := 1
const FAN_DURATION := 0.3
const MAX_FAN := 10  # Optional limit for clarity

var fan_clones: Array[CardSuperDetailUI] = []
var timer := Timer.new()
var clear_timer_pending := false

func _ready() -> void:
	add_child(fan_layer)
	add_child(timer)
	fan_layer.z_as_relative = true
	fan_layer.z_index = -1
	area_2d.mouse_entered.connect(_on_area_mouse_entered)
	area_2d.mouse_exited.connect(_on_area_mouse_exited)
	timer.wait_time = 0.2
	timer.one_shot = true


func _process(_delta):
	if timer.time_left == 0.0 and clear_timer_pending:
		_clear_fan()
		clear_timer_pending = false


func _on_area_mouse_entered() -> void:
	print("mouse entered")
	clear_timer_pending = false
	timer.stop()
	if fan_clones.size() == 0:
		_show_matching_fan()


func _on_area_mouse_exited() -> void:
	print("mouse exited")
	clear_timer_pending = true
	timer.start()
	

func _show_matching_fan() -> void:
	if not card:
		return

	var count = clamp(matches - 1, 0, MAX_FAN)  # Exclude original

	for i in range(count):
		var clone: CardSuperDetailUI = SUPER_DETAIL_UI.instantiate() as CardSuperDetailUI
		clone.card = card
		clone.modulate.a = 0.0
		clone.is_hoverable = false
		clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clone.pivot_offset = Vector2(50.0, 100)

		fan_layer.add_child(clone)
		fan_clones.append(clone)

		var tween := create_tween()
		tween.tween_property(clone, "modulate:a", 1.0, FAN_DURATION)
		tween.tween_property(clone, "rotation_degrees", (5 * i), FAN_DURATION)
		tween.parallel().tween_property(clone, "position", Vector2(10 * i, -5* i), FAN_DURATION)

	# Reorder children so later cards render underneath earlier ones
	for i in range(fan_clones.size()):
		fan_layer.move_child(fan_clones[fan_clones.size() - 1 - i], i)

func _clear_fan() -> void:
	for i in range(fan_clones.size()):
		var clone = fan_clones[i]
		if clone.tween and clone.tween.is_running():
			clone.tween.kill()
		clone.tween = create_tween()
		clone.tween.tween_property(clone, "rotation_degrees", (0), FAN_DURATION)
		clone.tween.parallel().tween_property(clone, "position", Vector2.ZERO, FAN_DURATION)
		clone.tween.tween_property(clone, "modulate:a", 0.0, FAN_DURATION / 2)
		
		clone.tween.tween_callback(clone.queue_free)
	fan_clones.clear()
