class_name StatusUI
extends Control

@export var status: Status : set = set_status

@onready var status_icon: TextureRect = $StatusIcon
@onready var duration: Label = $Duration
@onready var stacks: Label = $Stacks

#test functionality
#func _ready() -> void:
	#await get_tree().create_timer(2).timeout
	#status.duration -= 1
	#status.stacks -= 2

func set_status(new_status: Status) -> void:
	if not is_node_ready():
		await ready
	
	status = new_status
	status_icon.texture = status.icon
	duration.visible = status.stack_type == Status.StackType.DURATION
	stacks.visible = status.stack_type == Status.StackType.INTENSITY
	custom_minimum_size = status_icon.size
	
	if duration.visible:
		custom_minimum_size = duration.size + duration.position
	elif stacks.visible:
		custom_minimum_size = stacks.size + stacks.position
	
	if not status.status_changed.is_connected(_on_status_changed):
		status.status_changed.connect(_on_status_changed)
	
	_on_status_changed()


func _on_status_changed() -> void:
	if not status:
		return
	
	if status.can_expire and status.duration <= 0:
		queue_free()
	
	if status.stack_type == Status.StackType.INTENSITY and status.stacks == 0:
		queue_free()
	
	duration.text = str(status.duration)
	stacks.text = str(status.stacks)
