extends CanvasLayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var trainer_name: Label = $TrainerName
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pkmn_party_box: HBoxContainer = %PkmnPartyBox
@onready var pokeball: TextureRect = %Pokeball

const POKEBALL = preload("res://art/pokeball.png")
const TRAINER_BATTLE = preload("res://art/music/trainer_battle.mp3")

var enemy_party_count: int

func play_intro() -> void:
	MusicPlayer.play(TRAINER_BATTLE, true)
	animation_player.play("bg_slide")
	populate_pokeballs()
	await animation_player.animation_finished
	queue_free()

func populate_pokeballs() -> void:
	for child in pkmn_party_box.get_children():
		child.queue_free()
	for each in enemy_party_count:
		var new_ball = TextureRect.new()
		new_ball.texture = POKEBALL
		new_ball.modulate = Color(1,1,1,0)
		new_ball.custom_minimum_size = Vector2(0,0)
		new_ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_ball.stretch_mode =TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pkmn_party_box.add_child(new_ball)
	var tween = create_tween()
	tween.tween_interval(.5)
	for child in pkmn_party_box.get_children():
		tween.tween_property(child,"modulate", Color(1,1,1,1), .2)
		tween.parallel().tween_property(child, "custom_minimum_size", Vector2(35,35), .1)
	tween.tween_interval(.2)
	await tween.finished
	tween = create_tween()
	for child in pkmn_party_box.get_children():
		tween.tween_property(child,"modulate", Color(1,1,1,0), .2)
		tween.parallel().tween_property(child, "custom_minimum_size", Vector2(75,75), .2)
		tween.parallel()
	await tween.finished
