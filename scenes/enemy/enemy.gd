#enemy.gd
class_name Enemy
extends Area2D

const ARROW_OFFSET := 20
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")
const COMBAT_TEXT := preload("res://scenes/ui/combat_text_label.tscn")
const WOBBLE: AudioStream = preload("res://art/sounds/sfx/wobble.wav")
const BREAKOUT = preload("res://art/sounds/sfx/pokeball_release.wav")
const CAUGHT = preload("res://art/sounds/sfx/caught.wav")
const SNORE := preload("res://art/sounds/sfx/snore.mp3")

const PULSE_SHADER := preload("res://pulse.gdshader")

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var intent_ui: IntentUI = %IntentUI as IntentUI
@onready var animation_handler: Node = $AnimationHandler
@onready var name_container: PanelContainer = %NameContainer
@onready var unit_status_indicator: UnitStatusIndicator = %UnitStatusIndicator
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var catch_animator_tscn = preload("res://scenes/enemy/catch_animator.tscn")
var catch_animator: Node2D = null

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action
var spawn_coords: Vector2

#effect bools
var is_catchable: bool = false
var is_caught: bool = false
var is_asleep: bool = false
var is_confused: bool = false
var is_froze: bool = false
var skip_turn: bool = false
var has_slept: bool = false

#catching
var max_wobble = 3
var current_wobble = 0
var is_trainer_pkmn: bool = false

#dialogue delay
var enemy_text_delay: float = 0.4

var last_damage_taken: int = 0

func _ready():
	await get_tree().process_frame
	#connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	#connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	if stats and stats.species_id != "" and stats.uid == "":
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
		sprite_2d.texture = stats.art
		setup_ai()
		print("Stats or species_id pre-exists - adding pokemon.")
	intent_ui.parent = self
	intent_ui.status_handler = status_handler
	
	var pulse_material := ShaderMaterial.new()
	pulse_material.shader = PULSE_SHADER
	pulse_material.set_shader_parameter("width", 0.0)  # start with no highlight
	sprite_2d.material = pulse_material
	spawn_coords = global_position
	
	#TESTING add status effect here:
	#var status := preload("res://statuses/dodge.tres")
	#status_handler.add_status(status.duplicate())
	#status_handler.add_status(status.duplicate())
	#status_handler.add_status(status.duplicate())
	#status_handler.add_status(status.duplicate())


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
		#for id in stats.move_ids:
			#print("this is in the action picker: ", id)
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
	await status_effect_checks()
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
	Events.battle_text_requested.emit("Enemy [color=red]%s[/color] used %s!" % [stats.species_id.capitalize(), current_action.action_name])
	await get_tree().create_timer(enemy_text_delay).timeout
	current_action.perform_action()
	enemy_action_picker.select_valid_target()

	
	if status_handler.has_status("seeded"):
		get_tree().create_timer(.5).timeout
		var seeded := status_handler.get_status("seeded")
		Events.enemy_seeded.emit(seeded)


func status_effect_checks() -> void:
	if status_handler.get_child_count() == 0 and !is_asleep and !is_confused:
		print("[ENEMY] no status effects detected on %s - turn executing normally" % stats.species_id.capitalize())
		return
		
	if status_handler.has_status("flinched"):
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] flinched!" % stats.species_id.capitalize())
		await get_tree().create_timer(enemy_text_delay).timeout
		print("😬 Enemy flinched will skip turn.")
		status_handler.remove_status("flinched")
		skip_turn = true
		
	if status_handler.has_status("froze"):
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is FROZEN!" % stats.species_id.capitalize())
		await get_tree().create_timer(enemy_text_delay).timeout
		print("🥶 Enemy is FROZE will skip turn.")
		status_handler.remove_status("froze")
		is_froze = false
		skip_turn = true
	
	if is_asleep:
		var slp_tween := create_tween()
		slp_tween.tween_callback(Shaker.shake.bind(self, 15, 0.25))
		slp_tween.tween_interval(0.6)
		slp_tween.tween_callback(Shaker.shake.bind(self, 15, 0.25))
		SFXPlayer.play(SNORE)
		await get_tree().create_timer(1).timeout

		var stuck_asleep := 0.4
		var roll := randf()
		if roll < stuck_asleep:
			slp_tween = create_tween()
			slp_tween.tween_callback(Shaker.shake.bind(self, 25, 0.15))
			slp_tween.tween_interval(0.17)
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is fast asleep..!" % stats.species_id.capitalize())
			await get_tree().create_timer(1).timeout
			is_asleep = true
			has_slept = true
			skip_turn = true
			return
		else:
			print("✅ Enemy %s wakes up and acts normally." % stats.species_id.capitalize())
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] WOKE UP!" % stats.species_id.capitalize())
			skip_turn = false
			has_slept = true
			is_asleep = false
			unit_status_indicator.update_status_display(self)
			await get_tree().create_timer(2).timeout

	if status_handler.has_status("paralyze"):
		await get_tree().create_timer(enemy_text_delay).timeout
		var chance := 0.25
		var roll := randf()
		if roll < chance:
			print("⚡ Enemy %s is fully paralyzed!" % stats.species_id.capitalize())
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is PARALYZED!" % stats.species_id.capitalize())
			SFXPlayer.play(preload("res://art/sounds/sfx/stat_paralyze.mp3"))
			var tween := create_tween()
			tween.tween_callback(Shaker.shake.bind(self, 25, 0.15))
			tween.tween_interval(0.17)
			skip_turn = true
			return
		else:
			print("✅ Enemy %s resists paralysis and acts normally." % stats.species_id.capitalize())
		
	if status_handler.has_status("confused"):
			print("⚠️ %s is CONFUSED — selecting from confused_target_pool" % stats.species_id)
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is CONFUSED!" % stats.species_id.capitalize())
			await get_tree().create_timer(enemy_text_delay).timeout
			enemy_action_picker.select_confused_target()
			is_confused = true
	else:
		is_confused = false


func catch_check() -> void:
	await get_tree().create_timer(enemy_text_delay).timeout
	if stats.health <= 0:
			print("❌ Skipping catch check: %s already fainted." % stats.species_id)
			return

	if status_handler.has_status("catching"):
		Events.battle_text_requested.emit("Enemy [color=red]%s[/color] is trying to break free!" % stats.species_id.capitalize())
		await get_tree().create_timer(enemy_text_delay).timeout
		print("🎯 %s is being caught, will skip turn." % self)
		catch_animator.animated_sprite_2d.play("shakes")
		SFXPlayer.play(WOBBLE)
		await get_tree().create_timer(.5).timeout
		SFXPlayer.play(WOBBLE)
		await catch_animator.animated_sprite_2d.animation_finished
		
		if did_escape_catch():
			print("💥 %s broke free!" % stats.species_id)
			catch_animator.animated_sprite_2d.play("breakout")
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] BROKE FREE!" % stats.species_id.capitalize())
			SFXPlayer.play(BREAKOUT)
			await catch_animator.animated_sprite_2d.animation_finished
			await get_tree().create_timer(enemy_text_delay).timeout
			sprite_2d.visible = true
			catch_animator.queue_free()
			catch_animator = null
			status_handler.remove_status("catching")
		elif was_caught():
			await get_tree().create_timer(.2).timeout
			print("✅ %s was caught!" % stats.species_id)
			catch_animator.animated_sprite_2d.play("success")
			SFXPlayer.play(CAUGHT)
			await catch_animator.animated_sprite_2d.animation_finished
			Events.battle_text_requested.emit("Enemy [color=red]%s[/color] was caught!" % stats.species_id.capitalize())
			await get_tree().create_timer(enemy_text_delay).timeout
			take_damage(stats.health, Modifier.Type.DMG_TAKEN)
			skip_turn = true
		else:
			skip_turn = true
			catch_animator.animated_sprite_2d.play("rest")
	

func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	#if stats.health <= 0:
		#return
	
	last_damage_taken = 0
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)
	
	if modified_damage > 0:
		if status_handler.has_status("rage"):
			var atkup = preload("res://statuses/attack_up.tres").duplicate()
			atkup.stacks = 2
			var rage_effect = StatusEffect.new()
			rage_effect.source = self
			rage_effect.status = atkup
			rage_effect.execute([self])
		var dmg_text := COMBAT_TEXT.instantiate()
		add_child(dmg_text)
		dmg_text.show_text("%s" % modified_damage)
		
		last_damage_taken = modified_damage
	
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
			elif stats.health <= 0:
				Events.enemy_fainted.emit(self)
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
	var base_chance := 0.3 
	var bonus = clamp(hp_ratio, 0.0, 1.0)  # More HP = more likely to escape
	var escape_chance = base_chance + (bonus * 0.4)  # 30% to 70% chance to break out
	current_wobble += 1
	return randf() > escape_chance

func was_caught() -> bool:
	if current_wobble >= max_wobble:
		return true
	var hp_ratio := float(stats.health) / float(stats.max_health)
	var base_chance := 0.4  # Base 40% chance to break free
	var bonus = clamp(hp_ratio, 0.0, 1.0)  # More HP = more likely to escape
	var catch_chance = base_chance + (bonus * 0.4)  # 40% to 80% chance to break out
	current_wobble += 1
	return randf() > catch_chance


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
	var pulse_material := ShaderMaterial.new()
	pulse_material.shader = PULSE_SHADER
	pulse_material.set_shader_parameter("width", 1.5)  # start with no highlight
	sprite_2d.material = pulse_material
	name_container.pkmn_name.text = stats.species_id.capitalize()
	name_container.show()

func _on_area_exited(_area: Area2D) -> void:
	var pulse_material := ShaderMaterial.new()
	pulse_material.shader = PULSE_SHADER
	pulse_material.set_shader_parameter("width", 0)  # start with no highlight
	sprite_2d.material = pulse_material
	name_container.hide()


func dodge_check() -> bool:
	if status_handler.has_status("dodge"):
		var dodge_stacks = status_handler.get_status_stacks("dodge")
		var dodge_chance = dodge_stacks * 0.1
		var dodge_outcome = randf()
		var dodge = status_handler.get_status("dodge")
		dodge.stacks -= 1

		if dodge_outcome < dodge_chance:
			Events.battle_text_requested.emit("%s was able to DODGE the attack!" % stats.species_id.capitalize())
			_play_dodge_tween()
			return true
	return false


func _play_dodge_tween() -> void:
	var start_pos := global_position
	var dodge_offset := Vector2.LEFT * 24
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", start_pos - dodge_offset, 0.1)
	show_combat_text("DODGE!")
	tween.tween_property(self, "global_position", start_pos - dodge_offset, 0.5)
	tween.tween_property(self, "global_position", start_pos, 0.1)


func show_combat_text(text: String, color: Color = Color.WHITE) -> void:
	var label := COMBAT_TEXT.instantiate()
	add_child(label)
	label.show_text(text, color)


func _on_mouse_entered() -> void:
	var pulse_material := ShaderMaterial.new()
	pulse_material.shader = PULSE_SHADER
	pulse_material.set_shader_parameter("width", 1.5)  # start with no highlight
	sprite_2d.material = pulse_material
	name_container.pkmn_name.text = stats.species_id.capitalize()
	name_container.show()

func _on_mouse_exited() -> void:
	var pulse_material := ShaderMaterial.new()
	pulse_material.shader = PULSE_SHADER
	pulse_material.set_shader_parameter("width", 0)  # start with no highlight
	sprite_2d.material = pulse_material
	name_container.hide()
