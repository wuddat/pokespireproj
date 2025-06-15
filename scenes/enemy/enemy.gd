#enemy.gd
class_name Enemy
extends Area2D

const ARROW_OFFSET := 20
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")
const WOBBLE: AudioStream = preload("res://art/sounds/sfx/wobble.wav")
const BREAKOUT = preload("res://art/sounds/sfx/pokeball_release.wav")
const CAUGHT = preload("res://art/sounds/sfx/caught.wav")

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var intent_ui: IntentUI = %IntentUI as IntentUI

@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var catch_animator_tscn = preload("res://scenes/enemy/catch_animator.tscn")
var catch_animator: Node2D = null

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action

var is_catchable: bool = false
var is_caught: bool = false
var skip_turn: bool = false
var has_slept: bool = false

var max_wobble = 3
var current_wobble = 0

func _ready():
	await get_tree().process_frame
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	
	if stats and stats.species_id != "":
		#print("READY: species_id = ", stats.species_id)
		var poke_data = Pokedex.get_pokemon_data(stats.species_id)
		#print("Pokedata: ", poke_data)
		if poke_data:
			stats.load_from_pokedex(poke_data)
			sprite_2d.texture = stats.art
			setup_ai()
		else:
			print("No Pokedex data found for: " + stats.species_id)
	else:
		print("Stats or species_id not set yet.")


func set_current_action(value: EnemyAction) -> void:
	current_action = value
	update_intent()



func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
	
	update_enemy()
	


func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()
		
	var new_action_picker: EnemyActionPicker = stats.ai.instantiate()
	add_child(new_action_picker)
	enemy_action_picker = new_action_picker
	enemy_action_picker.enemy = self
	
	if enemy_action_picker.has_method("setup_actions_from_moves"):
		enemy_action_picker.setup_actions_from_moves(self, stats.move_ids)
	else:
			print("enemy_action_picker does NOT have setup_actions_from_moves")
	await get_tree().process_frame
	update_action()
	


func update_stats() -> void:
	stats_ui.update_stats(stats)


func update_action() -> void:
	if not enemy_action_picker:
		return
	
	if not current_action:
		current_action = enemy_action_picker.get_action()
		return
	
	var new_conditional_action := enemy_action_picker.get_first_conditional_action()
	if new_conditional_action and current_action != new_conditional_action:
		current_action = new_conditional_action
	
	update_intent()


func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
	
	sprite_2d.texture = stats.art
	arrow.position = Vector2.UP * (sprite_2d.get_rect().size.y / 2 + ARROW_OFFSET)
	setup_ai()
	update_stats()


func update_intent() -> void:
	await get_tree().process_frame
	if not current_action:
		#print("ENEMY.GD update_intent: No current_action for enemy %s" % self.name)
		return
	#print("ENEMY.GD target BEFORE intent update: %s" % current_action.target.stats.species_id)
	current_action.update_intent_text()
	#print("ENEMY.GD target AFTER intent update: %s" % current_action.target.stats.species_id)
	intent_ui.update_intent(current_action.intent)


func do_turn() -> void:
	stats.block = 0
	enemy_action_picker._on_party_shifted()
	status_effect_checks()
	await catch_check()

	if skip_turn:
		print("⛔️ Enemy skipping turn due to skip_turn flag.")
		skip_turn = false  # Reset for next round
		Events.enemy_action_completed.emit(self)
		return

	if not current_action:
		return
		
	current_action.update_intent_text()
	intent_ui.update_intent(current_action.intent)
	current_action.perform_action()
	enemy_action_picker.select_valid_target()
	skip_turn = false
	
	if status_handler.has_status("seeded"):
		get_tree().create_timer(.5).timeout
		var seeded := status_handler.get_status("seeded")
		Events.enemy_seeded.emit(seeded)


func status_effect_checks() -> void:
	if status_handler.has_status("flinched"):
		print("😬 Enemy flinched and will skip turn.")
		status_handler.remove_status("flinched")
		skip_turn = true
		
	if status_handler.has_status("confused"):
			print("⚠️ %s is CONFUSED — selecting from confused_target_pool" % stats.species_id)
			enemy_action_picker.select_confused_target()


func catch_check() -> void:
	if stats.health <= 0:
			print("❌ Skipping catch check: %s already fainted." % stats.species_id)
			return

	if status_handler.has_status("catching"):
		print("🎯 %s is being caught, will skip turn." % self)
		catch_animator.animated_sprite_2d.play("shakes")
		SFXPlayer.play(WOBBLE)
		await get_tree().create_timer(.5).timeout
		SFXPlayer.play(WOBBLE)
		await catch_animator.animated_sprite_2d.animation_finished
		
		if did_escape_catch():
			print("💥 %s broke free!" % stats.species_id)
			catch_animator.animated_sprite_2d.play("breakout")
			SFXPlayer.play(BREAKOUT)
			await catch_animator.animated_sprite_2d.animation_finished
			sprite_2d.visible = true
			catch_animator.queue_free()
			catch_animator = null
			status_handler.remove_status("catching")
			current_wobble = 0
		elif was_caught():
			await get_tree().create_timer(.2).timeout
			print("✅ %s was caught!" % stats.species_id)
			catch_animator.animated_sprite_2d.play("success")
			SFXPlayer.play(CAUGHT)
			await catch_animator.animated_sprite_2d.animation_finished
			take_damage(stats.health, Modifier.Type.DMG_TAKEN)
			skip_turn = true
		else:
			skip_turn = true
			catch_animator.animated_sprite_2d.play("rest")
	

func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 25, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	update_intent()
	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0 and status_handler.has_status("catching"):
				is_catchable = true
				catch_animator.animated_sprite_2d.play("success")
				await catch_animator.animated_sprite_2d.animation_finished
				print("enemy was caught ", is_catchable)
				print("Emitting captured signal with:", self.stats)
				mark_as_caught()
				Events.enemy_fainted.emit(self)
				queue_free()
			elif stats.health <= 0:
				Events.enemy_fainted.emit(self)
				queue_free()
	)


func gain_block(block: int, mod_type:Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	var modified_block := modifier_handler.get_modified_value(block, mod_type)
	
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	var up_position := start + Vector2(0, -10)
	tween.tween_property(self, "position", up_position, 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(stats.gain_block.bind(modified_block))
	tween.tween_interval(0.17)


func enter_catching_state():
	if catch_animator:
		return
	catch_animator = catch_animator_tscn.instantiate()
	catch_animator.name = "CatchAnimator"
	add_child(catch_animator)	
	catch_animator.global_position = sprite_2d.global_position
	sprite_2d.visible = false
	catch_animator.visible = true
	catch_animator.animated_sprite_2d.play("catch")
	await catch_animator.animated_sprite_2d.animation_finished
	catch_animator.animated_sprite_2d.play("rest")

func did_escape_catch() -> bool:
	# TODO catchrate formula
	var hp_ratio := float(stats.health) / float(stats.max_health)
	var base_chance := 0.4  # Base 40% chance to break free
	var bonus = clamp(hp_ratio, 0.0, 1.0)  # More HP = more likely to escape
	var escape_chance = base_chance + (bonus * 0.4)  # 40% to 80% chance to break out
	
	return randf() < escape_chance

func was_caught() -> bool:
	if current_wobble >= max_wobble:
		return true
	var hp_ratio := float(stats.health) / float(stats.max_health)
	var base_chance := 0.4  # Base 40% chance to break free
	var bonus = clamp(hp_ratio, 0.0, 1.0)  # More HP = more likely to escape
	var catch_chance = base_chance + (bonus * 0.4)  # 40% to 80% chance to break out
	current_wobble += 1
	return randf() < catch_chance


func mark_as_caught() -> void:
	if is_caught:
		return
	is_caught = true
	skip_turn = true
	is_catchable = false
	
	print("mark_as_caught signal with:", stats)
	var pkmn_to_add = Pokedex.create_pokemon_instance(stats.species_id)
	Events.pokemon_captured.emit(PokemonStats.from_enemy_stats(pkmn_to_add))
	
	#TODO if this breaks combat - update to resolve end of combat with enemies still alive
	enemy_action_picker = null
	# maybe emit a signal instead?
	

func _on_area_entered(_area: Area2D) -> void:
	arrow.show()


func _on_area_exited(_area: Area2D) -> void:
	arrow.hide()
