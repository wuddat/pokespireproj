class_name BattleDialogueManager
extends PanelContainer

@onready var label: RichTextLabel = %BattleText
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var tween: Tween

const PC_MENU_SELECT = preload("res://art/sounds/sfx/pc_menu_select.wav")

var message_queue: Array[String] = []
var is_displaying := false
var is_typing := false
var waiting_for_input := false
var auto_advance := true
var fade_duration := 0.5
var advance_timer: SceneTreeTimer = null


func _ready():
	Events.battle_won.connect(_on_battle_won)
	Events.evolution_triggered.connect(_on_evolution_triggered)
	Events.evolution_completed.connect(_on_evolution_completed)
	modulate.a = 0
	hide()
	Events.battle_text_requested.connect(_enqueue_message)
	set_process_input(true)


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


func _type_text(text: String) -> void:
	if text.strip_edges() == "":
		label.text = ""
		hide()
		Events.battle_text_completed.emit()
		return
		
	is_typing = true
	label.text = text
	label.visible_ratio = 0.0

	var duration := text.length() * 0.02
	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, duration)

	while is_typing and tween.is_running():
		await get_tree().process_frame

	label.visible_ratio = 1.0
	is_typing = false


func _wait_for_continue() -> void:
	if auto_advance:
		advance_timer = get_tree().create_timer(1)
		await advance_timer.timeout
		advance_timer = null
	else:
		waiting_for_input = true
		while waiting_for_input:
			await get_tree().process_frame
		waiting_for_input = false
		SFXPlayer.play(PC_MENU_SELECT)
		if advance_timer:
			advance_timer.kill()
			advance_timer = null


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


func _input(event: InputEvent) -> void:
	if not is_displaying:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_typing:
			label.visible_ratio = 1.0
			is_typing = false
			if is_instance_valid(tween):
				tween.kill()
		elif waiting_for_input:
			waiting_for_input = false
			if advance_timer:
				advance_timer.kill()
				advance_timer = null

func _on_evolution_triggered() -> void:
	message_queue.clear()
	_fade_out()
	
func _on_evolution_completed() -> void:
	message_queue.clear()
	show()

func _on_battle_won() -> void:
	message_queue.clear()
	_fade_out()
