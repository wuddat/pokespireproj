extends CanvasLayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
const WILD_BATTLE = preload("res://art/music/18 Battle (VS Wild Pokemon).mp3")

func play_intro() -> void:
	MusicPlayer.play(WILD_BATTLE, true)
	animation_player.play("bg_slide")
	await animation_player.animation_finished
	queue_free()
