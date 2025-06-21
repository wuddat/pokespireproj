class_name BattleDialogueManager
extends PanelContainer

@onready var label: RichTextLabel = %BattleText
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var tween := create_tween()


var message_queue: Array[String] = []
var is_displaying := false
var is_typing := false
var auto_advance := true
var fade_duration := 0.5

func _ready():
	modulate.a = 0
	hide()
	Events.battle_text_requested.connect(_enqueue_message)


func _enqueue_message(text: String) -> void:
	message_queue.append(text)
	if is_displaying:
		return
	is_displaying = true
	await _fade_in()
	
	while not message_queue.is_empty():
		var next_text = message_queue.pop_front()
		await _type_text(next_text)
		await _wait_for_continue()
		
	is_displaying = false
	await _fade_out()
	label.text = ""
	Events.battle_text_completed.emit()


func _display_next_message() -> void:
	if message_queue.is_empty():
		is_displaying = false
		await _fade_out()
		return

	is_displaying = true
	show()
	var next_text = message_queue.pop_front()
	await _type_text(next_text)
	await _wait_for_continue()
	_display_next_message()


func _type_text(text: String) -> void:
	is_typing = true
	label.text = text
	label.visible_ratio = 0.0

	var duration := text.length() * 0.02
	var tween := create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, duration)
	await tween.finished

	is_typing = false

func _wait_for_continue() -> void:
	if auto_advance:
		await get_tree().create_timer(1).timeout
	else:
		await _wait_for_input()

func _wait_for_input() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept"):
			break


func _fade_in() -> void:
	modulate.a = 0
	show()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	await tween.finished

func _fade_out() -> void:
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	hide()
