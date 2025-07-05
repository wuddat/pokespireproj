#status_handler.gd
class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_UI = preload("res://scenes/status_handler/status_ui.tscn")
const STATUS_DETAIL_OVERLAY_DELAY := 0.5

@export var status_owner: Node2D

var health_ui_status_container: Node = null
var is_mouse_over := false


func set_status_ui_container(container: Node) -> void:
	health_ui_status_container = container


func apply_statuses_by_type(type: Status.Type) -> void:
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
		tween.tween_callback(func():
			status.apply_status(status_owner)
			match status.type:
				Status.Type.START_OF_TURN:
					if status.has_method("on_start_of_turn"):
						status.on_start_of_turn(status_owner)
				Status.Type.END_OF_TURN:
					if status.has_method("on_end_of_turn"):
						status.on_end_of_turn(status_owner)
		)
		tween.tween_interval(STATUS_APPLY_INTERVAL)

	tween.finished.connect(func(): statuses_applied.emit(type))



func add_status(status: Status) -> void:
	var stackable := status.stack_type != Status.StackType.NONE

	if not has_status(status.id):
		var new_status_ui := STATUS_UI.instantiate() as StatusUI

		#  LOGIC: Add to StatusHandler scene tree for status logic to work
		add_child(new_status_ui)

		#  VISUALS: Also add a copy to the HealthBarUI (optional)
		if health_ui_status_container:
			var visual_ui := STATUS_UI.instantiate()
			visual_ui.status = status
			health_ui_status_container.add_child(visual_ui)

		new_status_ui.status = status
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.status.initialize_status(status_owner)

		print(status.id, " new status effect added")
		return

	# If not stackable, already present — do nothing
	if not status.can_expire and not stackable:
		return

	# If duration stackable
	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		get_status(status.id).duration += status.duration
		print(status.id, " effect duration stacked")
		return

	# If intensity stackable
	if status.stack_type == Status.StackType.INTENSITY:
		var existing := get_status(status.id)
		existing.stacks += status.stacks
		print(status.id, " effect stacked")
		existing.apply_status(status_owner)
		return



func has_and_consume_status(id: String) -> bool:
	if has_status(id):
		remove_status(id)
		return true
	return false


func clear_all_statuses() -> void:
	for child in get_children():
		if child is StatusUI:
			child.queue_free()
	if health_ui_status_container:
		for child in health_ui_status_container.get_children():
			if child is StatusUI:
				child.queue_free()



func has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true
			
	return false


func get_status_stacks(id: String) -> int:
	var status := get_status(id)
	if status:
		return status.stacks
	return 0


func get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status
			
	return null


func decrement_status(id: String) -> void:
	var status: Status = get_status(id)
	if status.stacks >= 1:
		status.stacks -= 1
	if status.duration >= 1 and status.can_expire == true:
		status.duration -= 1

func increment_status(id: String) -> void:
	var status: Status = get_status(id)
	if status.stacks >= 1:
		status.stacks += 1
	if status.duration >= 1 and status.can_expire == true:
		status.duration += 1

func _get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
		
	return statuses


func has_any_status() -> bool:
	for child in get_children():
		if child is StatusUI:
			return true
	return false


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
	# Remove from logic tree
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			status_ui.queue_free()

	# Remove from visual container
	if health_ui_status_container:
		for status_ui: StatusUI in health_ui_status_container.get_children():
			if status_ui.status.id == id:
				status_ui.queue_free()
