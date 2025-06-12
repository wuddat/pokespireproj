extends Node2D

signal animation_completed
@onready var sprite_current: Sprite2D = %sprite_current
@onready var sprite_evolved: Sprite2D = %sprite_evolved
@onready var background: TextureRect = %Background
@onready var label: Label = %Label
@onready var sprite_current_white: Sprite2D = %sprite_current_white
@onready var sprite_evolved_white: Sprite2D = %sprite_evolved_white

const EVOLUTION_FINISH = preload("res://art/music/evolution_finish.mp3")
const EVOLUTION_START = preload("res://art/music/evolution_start.mp3")
const EVO_DING_START = preload("res://art/music/evo_ding_start.mp3")

var start_position: Vector2
var from_texture: Texture2D
var to_texture: Texture2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")



func setup(from_species: String, to_species: String, origin_position: Vector2):
	start_position = origin_position

	var pokedex := Pokedex
	var from_data := pokedex.get_pokemon_data(from_species)
	var to_data := pokedex.get_pokemon_data(to_species)

	from_texture = load(from_data.get("sprite_path", "res://art/dottedline.png"))
	to_texture = load(to_data.get("sprite_path", "res://art/dottedline.png"))

	sprite_current.texture = from_texture
	sprite_evolved.texture = to_texture
	sprite_current_white.texture = from_texture
	sprite_evolved_white.texture = to_texture

	sprite_current.visible = true
	sprite_evolved.visible = false

	sprite_current_white.visible = true
	sprite_current_white.modulate = Color(1, 1, 1, 0)

	sprite_evolved_white.visible = false
	sprite_evolved_white.modulate = Color(1, 1, 1, 1)

	# ⚠️ Use global position directly
	sprite_current.global_position = start_position
	sprite_evolved.global_position = start_position
	sprite_current_white.global_position = start_position
	sprite_evolved_white.global_position = start_position

	await get_tree().process_frame
	animate(from_species, to_species)


func animate(from_species: String, to_species: String):
	print("🌀 Evolution animation starting...")
	MusicPlayer.pause()
	await SFXPlayer.play(EVO_DING_START, true)  
	
	
	
	var screen_center = Vector2(get_viewport().get_visible_rect().size / 2)
	print("🌍 Screen center is:", screen_center)
	print("📍 Start position is:", start_position)
	
	var bg_tween = create_tween()
	
	#fade in bg
	bg_tween.tween_property(background, "modulate:a", 0.5, 0.4)
	

	bg_tween.tween_property(label, "text", "What...?" % from_species.capitalize() , 0.4)
	bg_tween.tween_interval(1)
	await bg_tween.finished
	
	var tween = create_tween()
	#set evolution sprites to center
	sprite_evolved.global_position = screen_center
	sprite_current_white.global_position = screen_center
	sprite_evolved_white.global_position = screen_center
	
	#tween sprites to center
	tween.tween_property(sprite_current, "global_position", screen_center, 0.5).set_trans(Tween.TRANS_SINE)
	
	#fade in white
	tween.tween_property(sprite_current_white, "modulate:a", 1.0, 0.6)
	
	#show text
	var pkmn_is_evolving_tween = create_tween()
	pkmn_is_evolving_tween.tween_property(label, "text", "%s is evolving!" % from_species.capitalize() , 0.4)
	await pkmn_is_evolving_tween.finished
	await SFXPlayer.play(EVOLUTION_START)
	#hide original sprite
	tween.tween_callback(func(): sprite_current.visible = false)
	
	await tween.finished
	
	await get_tree().create_timer(0.5).timeout
	
	await play_flash_sequence()
	sprite_current_white.visible = false
	sprite_current.visible = false
	sprite_evolved_white.visible = false
	sprite_evolved.visible = true
	SFXPlayer.play(EVOLUTION_FINISH, true)  
	await get_tree().create_timer(0.5).timeout
	
	var fade_tween = create_tween()
	fade_tween.tween_property(sprite_evolved_white, "modulate:a", 0.0, 0.6)	
	await fade_tween.finished
	
	var evolved_text_tween = create_tween()
	evolved_text_tween.tween_property(label, "text", "%s evolved into %s!" % [from_species.capitalize(),to_species.capitalize()], 0.4)
	await evolved_text_tween.finished
	
	await get_tree().create_timer(0.5).timeout
	
	#return to start
	var return_tween := create_tween()
	return_tween.tween_property(sprite_evolved, "global_position", start_position, 0.5).set_trans(Tween.TRANS_SINE)
	await return_tween.finished
	await get_tree().create_timer(0.5).timeout
	MusicPlayer.resume()
	print("🏁 Evolution animation complete.")
	emit_signal("animation_completed")
	queue_free()





func play_flash_sequence() -> void:
	var flashes = 25
	sprite_evolved_white.visible = true
	sprite_evolved.visible = false
	for i in range(flashes):
		var wait_time = 1 / pow(1.2, i)
		await get_tree().create_timer(wait_time).timeout

		var show_current = i % 2 == 0
		sprite_current_white.visible = show_current
		sprite_evolved_white.visible = not show_current
