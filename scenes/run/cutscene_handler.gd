#cutscene_handler
class_name CutsceneHandler
extends CanvasLayer

const trainerscene := preload("res://scenes/animations/trainer_intro_scene.tscn")
const wildscene := preload("res://scenes/animations/wild_intro.tscn")
const mewtwo_phase_2 := preload("res://scenes/animations/mewtwo_phase_2.tscn")

func _ready() -> void:
	if not Events.mewtwo_phase_2_requested.is_connected(_on_mewtwo_phase_2_requested):
		Events.mewtwo_phase_2_requested.connect(_on_mewtwo_phase_2_requested)
	hide()

func _on_mewtwo_phase_2_requested() -> void:
	show()
	MusicPlayer.pause()
	print("transition requested")
	get_tree().paused = true
	var animation := mewtwo_phase_2.instantiate()
	add_child(animation)
	print("cutscene added")
	print("cutscene ready")
	animation.animation_player.play("dialogue")
	print("cutscene playing")
	await animation.animation_player.animation_finished
	print("cutscene complete")
	animation.queue_free()
	get_tree().paused = false
	MusicPlayer.resume()
