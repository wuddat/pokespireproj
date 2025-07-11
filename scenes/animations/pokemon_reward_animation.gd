extends Control

const CARD_SUPER_DETAIL = preload("res://scenes/ui/card_super_detail_ui.tscn")
const CARD_HOVER_DETAIL = preload("res://scenes/card_ui/card_hover_detail_ui.tscn")
const CARD_FLICK = preload("res://art/sounds/sfx/card_sfx1.mp3")
const POKEBALL_1 = preload("res://art/sounds/sfx/pokeball1.wav")
const POKEBALL_2 = preload("res://art/sounds/sfx/pokeball2.wav")
const POKEBALL_3 = preload("res://art/sounds/sfx/pokeball3.wav")
const POKEBALL_4 = preload("res://art/sounds/sfx/pokeball4.wav")
const POKEBALL_5 = preload("res://art/sounds/sfx/pokeball5.wav")
const POKEBALL_RELEASE = preload("res://art/sounds/sfx/pokeball_release.wav")
const JUMP = preload("res://art/sounds/move_sfx/jump.wav")
const PKMN_CAUGHT = preload("res://art/sounds/sfx/pkmn_caught.mp3")
const CAUGHT_PKMN_MUSIC = preload("res://art/sounds/sfx/caught_pkmn_music.mp3")
const VICTORY = preload("res://art/music/19 Victory (VS Wild Pokemon).mp3")

@onready var pkmn: Sprite2D = $pkmn
@onready var color_overlay: ColorRect = $pkmn/color_overlay
@onready var label: Label = $Label
@onready var catch_animator: Node2D = $CatchAnimator
@onready var grid_container: GridContainer = $GridContainer
@onready var bg: ColorRect = $bg

@export var caught_pkmn: PokemonStats
@export var cards: Array[Card]
@export var char_stats: CharacterStats

var animation_speed: float = .2
var pokeball: AnimatedSprite2D
var final_tween: Tween


func _ready() -> void:
	pokeball = catch_animator.animated_sprite_2d as AnimatedSprite2D
	bounce_sprite_to_center(catch_animator)
	pkmn.hide()

func bounce_sprite_to_center(sprite: Node2D) -> void:
	pkmn.texture = caught_pkmn.art
	pkmn.scale = Vector2(0,0)
	label.text = "You caught %s!" % caught_pkmn.species_id.capitalize()
	var viewport_size := get_viewport().get_visible_rect().size
	var target_y := (viewport_size.y / 2.0) + 20
	var start_y = -viewport_size.y
	var x := viewport_size.x / 2.0

	sprite.global_position = Vector2(x, start_y)

	var tween := create_tween()
	tween.tween_property(bg,"color", Color(0,0,0,1), .2)
	await tween.finished
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	# drop pkball
	tween.tween_property(sprite, "global_position:y", target_y, 0.8)
	tween.tween_interval(.2)
	await get_tree().create_timer(0.3).timeout
	SFXPlayer.play(POKEBALL_1)
	await get_tree().create_timer(0.3).timeout
	SFXPlayer.play(POKEBALL_2)
	await get_tree().create_timer(0.2).timeout
	SFXPlayer.play(POKEBALL_3)
	tween.tween_interval(.2)
	await tween.finished
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "global_position:y", target_y - 10, 1)
	pokeball.play("rest")
	await tween.finished
	
	# release pkmn
	pkmn.show()
	pokeball.play_backwards("catch")
	SFXPlayer.play(POKEBALL_RELEASE)
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(1.5,1.5), .2)
	tween.tween_property(sprite, "modulate", Color(1,1,1,0), .5)
	pkmn.global_position = pokeball.global_position
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(pkmn, "scale", Vector2(1,1), .2)
	tween.parallel().tween_property(color_overlay,"color",Color(1,1,1,0), 1)
	await tween.finished
	
	# show text
	SFXPlayer.play(PKMN_CAUGHT)
	tween = create_tween()
	tween.tween_property(label, "modulate", Color.WHITE, .2)
	tween.parallel().tween_property(label, "visible_ratio", 1, .5)
	await tween.tween_interval(2)
	
	#offset pkmn on screen
	tween.tween_callback(MusicPlayer.play_from_time.bind(VICTORY, 2, true)) 
	tween.tween_property(label, "modulate", Color(1,1,1,0), animation_speed)
	tween.tween_property(pkmn, "global_position", Vector2(viewport_size.x/7, viewport_size.y/2), animation_speed)
	await tween.finished
	pkmn.flip_h = true
	
	#display cards
	for card in cards:
		var new_card = CARD_SUPER_DETAIL.instantiate()
		var mini_card = CARD_HOVER_DETAIL.instantiate()
		add_child(new_card)
		grid_container.add_child(mini_card)
		new_card.pivot_offset = Vector2(new_card.size.x/2, new_card.size.y/2)
		new_card.card = card
		mini_card.card = card
		mini_card.modulate = Color(1,1,1,0)
		new_card.set_char_stats(char_stats)
		mini_card.set_char_stats(char_stats)
		new_card.global_position = pkmn.global_position
		new_card.scale = Vector2(0,0)
		new_card.modulate = Color(1,1,1,0)
		var card_tween := create_tween()
		SFXPlayer.pitch_play(CARD_FLICK)
		card_tween.tween_property(new_card,"scale", Vector2(1,1), animation_speed)
		card_tween.parallel().tween_property(new_card, "global_position", Vector2(viewport_size.x - (viewport_size.x/3),(viewport_size.y/2) - 100), animation_speed)
		card_tween.parallel().tween_property(new_card, "modulate", Color(1,1,1,1), animation_speed)
		await card_tween.tween_interval(.1)
		await card_tween.finished
		#await _wait_for_input()
		card_tween = create_tween()
		SFXPlayer.pitch_play(CARD_FLICK)
		card_tween.tween_property(new_card, "scale", Vector2(0,0), animation_speed)
		card_tween.parallel().tween_property(new_card,"modulate", Color(1,1,1,0), animation_speed)
		card_tween.parallel().tween_property(new_card,"global_position", Vector2(mini_card.global_position.x, mini_card.global_position.y), animation_speed)
		card_tween.parallel().tween_property(mini_card,"modulate", Color(1,1,1,1), animation_speed)
		card_tween.parallel().tween_interval(animation_speed)
		await card_tween.finished
		new_card.queue_free()
	await _wait_for_input()
	
	# dismiss cards
	for c in grid_container.get_children():
		await get_tree().create_timer(.1).timeout
		SFXPlayer.pitch_play(CARD_FLICK, 1.05, 1.1)
		tween = create_tween()
		tween.tween_property(c, "global_position", Vector2(viewport_size.x, 0), .2)
	
	#return pokemon
	catch_animator.global_position = pkmn.global_position
	pokeball.play("catch")
	SFXPlayer.play(JUMP)
	sprite.modulate = Color(1,1,1,1)
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(1,1), .2)
	tween.tween_property(sprite, "modulate", Color(1,1,1,1), .5)
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(pkmn, "scale", Vector2(0,0), .2)
	tween.parallel().tween_property(color_overlay,"color",Color(1,1,1,1), 1)
	await pokeball.animation_finished
	pokeball.play("rest")
	await tween.finished
	pokeball.play("throw")
	SFXPlayer.play(POKEBALL_5)
	tween = create_tween()
	tween.tween_property(sprite, "global_position", Vector2(sprite.global_position.x, start_y), .3)
	tween.parallel().tween_property(bg, "color", Color(0,0,0,0), .2)
	await tween.finished
	final_tween = create_tween()
	final_tween.tween_property(bg, "modulate", Color(0,0,0,0), .1)
	await final_tween.finished
	print("final_tween_finished in animation")
	queue_free()
	

func _wait_for_input() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("left_mouse"):
			break

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_mouse"):
		animation_speed = .05
