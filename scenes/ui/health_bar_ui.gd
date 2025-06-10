class_name HealthBarUI
extends PanelContainer

@onready var health: HealthUI = %HealthUI
@onready var label: Label = %Label
@onready var block_label: Label = %BlockLabel
@onready var block: HBoxContainer = %Block
@onready var fainted: Label = %Fainted
@onready var status_container: GridContainer = %StatusIcons

const STATUS_TOOLTIP_DELAY := 0.5
var status_timer: SceneTreeTimer = null

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func update_stats(stats: Stats) -> void:
	if block_label == null or health == null:
		await ready  # Wait until node is fully added to tree
	if block_label == null or health == null:
		push_warning("StatsUI is not fully initialized")
		return
	
	block_label.text = str(stats.block)
	
	health.update_stats(stats)
	health.health_image.visible = false
	label.text = str(stats.species_id)
	fainted.visible = stats.health <= 0
	block.visible = stats.block > 0

func add_status_ui(ui: StatusUI) -> void:
	status_container.add_child(ui)

func _on_mouse_entered() -> void:
	status_timer = get_tree().create_timer(STATUS_TOOLTIP_DELAY)
	await status_timer.timeout
	if status_timer:
		# Find all StatusUI nodes in this health bar
		var statuses: Array[Status] = []
		for child in status_container.get_children():
			if child is StatusUI and child.status:
				statuses.append(child.status)
		Events.status_tooltip_requested.emit(statuses)
		status_timer = null

func _on_mouse_exited() -> void:
	if status_timer:
		status_timer.cancel_free()
		status_timer = null
	Events.status_tooltip_hide_requested.emit()
