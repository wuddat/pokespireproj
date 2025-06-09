class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_UI = preload("res://scenes/status_handler/status_ui.tscn")
const STATUS_DETAIL_OVERLAY_DELAY := 0.5

@export var status_owner: Node2D

var is_mouse_over := false


func apply_statuses_by_type(type:Status.Type) -> void:
	if type == Status.Type.EVENT_BASED:
		return
	
	var status_queue: Array[Status] = _get_all_statuses().filter(
		func(status: Status):
			return status.type == type
	)
	if status_queue.is_empty():
		statuses_applied.emit(type)
		return
		
	var tween := create_tween()
	for status: Status in status_queue:
		tween.tween_callback(status.apply_status.bind(status_owner))
		tween.tween_interval(STATUS_APPLY_INTERVAL)
		
	tween.finished.connect(func(): statuses_applied.emit(type))


func add_status(status: Status) -> void:
	var stackable := status.stack_type != Status.StackType.NONE #check if stackable
	
	#add if new status
	if not _has_status(status.id):
		var new_status_ui := STATUS_UI.instantiate() as StatusUI
		add_child(new_status_ui)
		new_status_ui.status = status
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.status.initialize_status(status_owner)
		print(status.id," new status effect added")
		return
	
	#if status is a one time active and we already have - return
	if not status.can_expire and not stackable:
		return
	
	#if status duration is stackable - increase it
	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		_get_status(status.id).duration += status.duration
		print(status.id," effect duration stacked")
		return
	
	#if status itself is stackable, stack it
	if status.stack_type == Status.StackType.INTENSITY:
		_get_status(status.id).stacks += status.stacks
		print(status.id," effect stacked")


func has_and_consume_status(id: String) -> bool:
	if _has_status(id):
		remove_status(id)
		return true
	return false



func _has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true
			
	return false
	
	
func _get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status
			
	return null


func _get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
		
	return statuses


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1
		print(status.id," effect applied and duration reduced by 1")
		
func get_statuses() -> Array[Status]:
	return _get_all_statuses()

var status_timer: SceneTreeTimer = null

func _on_mouse_entered() -> void:
	status_timer = get_tree().create_timer(STATUS_DETAIL_OVERLAY_DELAY)
	await status_timer.timeout
	if status_timer:
		Events.status_tooltip_requested.emit(_get_all_statuses())
		status_timer = null

func _on_mouse_exited() -> void:
	if status_timer:
		status_timer.cancel_free()
		status_timer = null
	Events.status_tooltip_hide_requested.emit()

func remove_status(id: String) -> void:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			status_ui.queue_free()
