class_name EventScene
extends Control

@export var char_stats: CharacterStats
@export var run_stats: RunStats

@onready var description_label := %DescriptionLabel
@onready var choices_container := %ChoicesVBox

var event_data := {}  # Loaded from JSON or hardcoded dictionary

func _ready():
	# Load a random event
	var random_event_id = EventData.get_random_event_id()
	event_data = EventData.get_event(random_event_id)
	
	description_label.text = event_data["description"]
	for choice in event_data["choices"]:
		var btn := Button.new()
		btn.text = choice["text"]
		btn.pressed.connect(func(): _on_choice_selected(choice["effects"]))
		choices_container.add_child(btn)

func _on_choice_selected(effects: Dictionary) -> void:
	EventEffectResolver.apply(effects, char_stats, run_stats)
	Events.map_exited.emit(null)  # Or a dummy Room if needed
	queue_free()
