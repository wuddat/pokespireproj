extends CanvasLayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var trainer_name: Label = $TrainerName
@onready var animation_player: AnimationPlayer = $AnimationPlayer
const TRAINER_BATTLE = preload("res://art/music/trainer_battle.mp3")

func play_intro() -> void:
	MusicPlayer.play(TRAINER_BATTLE, true)
	animation_player.play("bg_slide")
	await animation_player.animation_finished
	queue_free()
