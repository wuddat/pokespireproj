#mewtwo_phase_2.gd
class_name MewtwoPhase2
extends CanvasLayer

const MEWTWO_BATTLE = preload("res://art/music/mewtwo_battle.mp3")
const THUNDER_PUNCH = preload("res://art/sounds/move_sfx/thunder_punch.mp3")
const WARP = preload("res://art/sounds/move_sfx/warp.mp3")
@onready var bg: ColorRect = $bg
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("fade_in")

func thunder_sound() -> void:
	SFXPlayer.play(THUNDER_PUNCH)

func warp_sound() -> void:
	SFXPlayer.play(WARP)

func battle_music() -> void:
	MusicPlayer.play(MEWTWO_BATTLE, true)
