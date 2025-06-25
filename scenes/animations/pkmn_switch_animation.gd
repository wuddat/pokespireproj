extends CanvasLayer
@onready var catch_animator: Node2D = $CatchAnimator

const OPEN_SOUND = preload("res://art/sounds/sfx/pokeball_release.wav")

@onready var pkmn_sprite: Sprite2D = $pkmn_sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer


var start_pos = Vector2(508, 76)
var end_pos = Vector2(394, 153)
var control_height = -50.0 # How high the arc is

func _ready() -> void:
	play_arc_throw(catch_animator)

func play_arc_throw(ball: Node2D) -> void:
	var tween = get_tree().create_tween()
	tween.tween_method(
		func(t):
			var p = lerp(start_pos, end_pos, t)
			p.y += control_height * 4 * t * (1 - t) # Parabola: -4h(t)(1−t)
			ball.position = p,
		0.0, 1.0, 0.6
	)
	await tween.finished
	var ball_pos = ball.global_position
	release_pokemon(ball_pos)

func release_pokemon(ball_pos) -> void:
	pkmn_sprite.global_position = ball_pos
	SFXPlayer.pitch_play(OPEN_SOUND)
	animation_player.play("release")
	await animation_player.animation_finished
	queue_free()
	
