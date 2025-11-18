extends CanvasLayer

signal animation_completed
@onready var background: TextureRect = %Background
@onready var label: Label = %Label
@onready var catch_animator: Node2D = $SpritesLayer/CatchAnimator
@onready var animation_player: AnimationPlayer = $SpritesLayer/AnimationPlayer
@onready var pkmn: Sprite2D = $SpritesLayer/pkmn
@onready var color_overlay: ColorRect = $SpritesLayer/pkmn/color_overlay

var target_pokemon_node: Enemy

const POKEBALL_1 = preload("res://art/sounds/sfx/pokeball1.wav")
const POKEBALL_2 = preload("res://art/sounds/sfx/pokeball2.wav")
const POKEBALL_3 = preload("res://art/sounds/sfx/pokeball3.wav")
const POKEBALL_4 = preload("res://art/sounds/sfx/pokeball4.wav")
const POKEBALL_5 = preload("res://art/sounds/sfx/pokeball5.wav")
const POKEBALL_RELEASE = preload("res://art/sounds/sfx/pokeball_release.wav")
const JUMP = preload("res://art/sounds/move_sfx/jump.wav")
const PKMN_CAUGHT = preload("res://art/sounds/sfx/pkmn_caught.mp3")
const CAUGHT_PKMN_MUSIC = preload("res://art/sounds/sfx/caught_pkmn_music.mp3")
const WOBBLE: AudioStream = preload("res://art/sounds/sfx/wobble.wav")


var start_position: Vector2
var target_pokemon_texture: Texture2D

var animation_speed: float = .2
var pokeball: AnimatedSprite2D
var final_tween: Tween

var screen_center: Vector2
var viewport_size: Vector2


const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

func _ready():
	##center things for testing delete this in final product
	#screen_center = Vector2(get_viewport().get_visible_rect().size / 2)
	#viewport_size = Vector2(get_viewport().get_visible_rect().size)
	#pkmn.global_position = screen_center
	pokeball = catch_animator.animated_sprite_2d as AnimatedSprite2D
	pokeball.global_position = target_pokemon_node.global_position
	
	#pokeball.global_position = screen_center
	pkmn.hide()
	await bg_fade_in()
	await begin_catch(pkmn)
	await bg_fade_out()
	Events.catch_completed.emit()


func bg_fade_in():
	print("🌀 Catch animation starting...")
	MusicPlayer.pause()
	
	#fade in bg
	var bg_tween = create_tween()
	bg_tween.tween_property(background, "modulate:a", 0.8, 0.4)
	await bg_tween.finished

func bg_fade_out():
	print("🌀 Catch animation completing...")
	
	#fade out bg
	var bg_tween = create_tween()
	bg_tween.tween_property(background, "modulate:a", 0, 0.4)
	await bg_tween.finished

func begin_catch(sprite: Node2D):
	pokeball.global_position = target_pokemon_node.global_position
	target_pokemon_node.hide()
	
	var tween := create_tween()
	pkmn.texture = target_pokemon_node.sprite_2d.texture
	pkmn.show()
	pokeball.play("catch")
	SFXPlayer.play(JUMP)
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(.2,.2), .2)
	tween.tween_property(sprite, "modulate", Color(1,1,1,0), .5)
	pkmn.global_position = pokeball.global_position
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(pkmn, "scale", Vector2(.2,.2), .2)
	tween.parallel().tween_property(color_overlay,"color",Color(1,1,1,0), 1)
	await pokeball.animation_finished
	pokeball.play("rest")
	await tween.finished
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	# drop pkball
	var start_y = pokeball.global_position.y
	var ground_y = start_y + 25
	pokeball.stop()
	pokeball.play("throw")
	tween.tween_property(pokeball, "global_position:y", ground_y, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(SFXPlayer.play.bind(POKEBALL_1))
	tween.tween_property(pokeball, "global_position:y", ground_y - 20, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(pokeball, "global_position:y", ground_y, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(SFXPlayer.play.bind(POKEBALL_2))
	tween.tween_property(pokeball, "global_position:y", ground_y - 10, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Third bounce - smallest
	tween.tween_property(pokeball, "global_position:y", ground_y, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(SFXPlayer.play.bind(POKEBALL_3))
	tween.tween_property(pokeball, "global_position:y", ground_y - 5, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pokeball, "global_position:y", ground_y, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	pokeball.play("rest")
	
	tween = create_tween()
	tween.tween_interval(1)
	await tween.finished
	await catch_check(target_pokemon_node)

func catch_check(enemy: Enemy):
	while enemy.status_handler.has_status("catching"):
		var timer = create_tween()
		timer.tween_interval(1)
		await timer.finished
		catch_animator.animated_sprite_2d.play("shakes")
		SFXPlayer.play(WOBBLE)
		await get_tree().create_timer(.5).timeout
		SFXPlayer.play(WOBBLE)
		await catch_animator.animated_sprite_2d.animation_finished
		catch_animator.animated_sprite_2d.play("rest")
		
		if enemy.did_escape_catch():
			print("💥 %s broke free!" % enemy.stats.species_id)
			catch_animator.animated_sprite_2d.play("breakout")
			SFXPlayer.play(enemy.BREAKOUT)
			await catch_animator.animated_sprite_2d.animation_finished
			enemy.visible = true
			enemy.status_handler.remove_status("catching")
			break
		elif enemy.was_caught():
			await get_tree().create_timer(.2).timeout
			print("✅ %s was caught!" % enemy.stats.species_id)
			catch_animator.animated_sprite_2d.play("success")
			SFXPlayer.play(enemy.CAUGHT)
			await catch_animator.animated_sprite_2d.animation_finished
			catch_animator.animated_sprite_2d.play("rest")
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] was caught!" % enemy.stats.species_id.capitalize())
			await get_tree().create_timer(enemy.enemy_text_delay).timeout
			enemy.take_damage(enemy.stats.health, Modifier.Type.DMG_TAKEN)
			enemy.skip_turn = true
			break
