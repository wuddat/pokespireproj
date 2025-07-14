#card_target_selector.gd
extends Node2D

const ARC_POINTS := 10
const PC_LOGOFF = preload("res://art/sounds/sfx/pc_logoff.wav")

@onready var area_2d: Area2D = $Area2D
@onready var card_arc: Line2D = $CanvasLayer/CardArc


var current_card: CardUI
var current_item: Item = null
var targeting := false


func _ready() -> void:
	Events.card_aim_started.connect(_on_card_aim_started)
	Events.card_aim_ended.connect(_on_card_aim_ended)
	Events.item_aim_started.connect(_on_item_aim_started)
	Events.item_aim_ended.connect(_on_item_aim_ended)
	
	
func _process(_delta: float) -> void:
	if not targeting:
		return
	
	area_2d.position = get_local_mouse_position()
	if current_card:
		card_arc.points = _get_points_from_card()
	elif current_item:
		card_arc.points = _get_points_from_origin(current_item.current_position + Vector2(20,35))


func _input(event: InputEvent) -> void:
	if not targeting or current_item == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("right_mouse"):
		Events.item_aim_ended.emit()
		current_item = null
		return
	if event.is_action_pressed("left_mouse"):
		if current_item.targets.is_empty():
			Events.item_aim_ended.emit()
			current_item = null
			return
	if event.is_action_pressed("left_mouse") and current_item.targets.size()> 0:
		if current_item.category == "tm" and not current_item.targets[0] is PokemonBattleUnit:
			print(current_item.targets[0].name)
			current_item.targets.clear()
			current_item = null
			Events.item_aim_ended.emit()
			SFXPlayer.pitch_play(PC_LOGOFF)
			return
		else:
			Events.item_used.emit(current_item)
			current_item.targets.clear()
			current_item = null
			Events.item_aim_ended.emit()
			return


func _get_points_from_card() -> Array:
	return _get_points_from_origin(current_card.global_position + Vector2(current_card.size.x/2, 0))

func _get_points_from_origin(start: Vector2) -> Array:
	var points := []
	var target := get_local_mouse_position()
	var distance := target - start

	for i in range(ARC_POINTS):
		var t := (1.0 / ARC_POINTS) * i
		var x := start.x + (distance.x / ARC_POINTS) * i
		var y := start.y + ease_out_cubic(t) * distance.y
		points.append(Vector2(x, y))
	
	points.append(target)
	return points

func ease_out_cubic(number: float) -> float:
	return 1.0 - pow(1.0 - number, 3.0)


func _on_card_aim_started(card: CardUI) -> void:
	if not card.card.is_single_targeted():
		return
	targeting = true
	area_2d.monitoring = true
	area_2d.monitorable = true
	current_card = card


func _on_item_aim_started(item: Item) -> void:
	current_item = item
	targeting = true
	area_2d.monitoring = true
	area_2d.monitorable = true


func _on_card_aim_ended(_card: CardUI) -> void:
	targeting = false
	card_arc.clear_points()
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false
	current_card = null


func _on_item_aim_ended() -> void:
	targeting = false
	card_arc.clear_points()
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false
	current_item = null


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not targeting:
		return
	
	if current_card:
		if not current_card.targets.has(area):
			current_card.targets.append(area)
			current_card.request_tooltip()
	elif current_item:
		if not current_item.targets.has(area):
			current_item.targets.append(area)
			print("current item targets:")
			for tar in current_item.targets:
				print(tar.stats.species_id)


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not targeting:
		return
	if current_card:
		current_card.targets.erase(area)
		current_card.request_tooltip()
	elif current_item:
		current_item.targets.erase(area)
