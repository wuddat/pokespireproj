class_name Enemy
extends Area2D

const ARROW_OFFSET := 20
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action

var is_catchable: bool = false
var is_caught: bool = false
var skip_turn: bool = false

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
	
		#status effect testing
	status_handler.status_owner = self
	var status := preload("res://statuses/critical.tres")
	status_handler.add_status(status)


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
	if current_action:
		current_action.update_intent_text()
		intent_ui.update_intent(current_action.intent)


func do_turn() -> void:
	stats.block = 0
	if skip_turn:
		Events.enemy_action_completed.emit(self)
	if status_handler._has_status("flinched"):
		print("Enemy flinched and skips turn!")
		status_handler.remove_status("flinched")
		Events.enemy_action_completed.emit(self)
		return
	
	if status_handler._has_status("catching"):
		print("%s is being caught, skipping turn." % self)
		Events.enemy_action_completed.emit(self)
		return
	
	if not current_action:
		return
	
	current_action.perform_action()


func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 25, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0 and status_handler._has_status("catching"):
				is_catchable = true
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


func mark_as_caught() -> void:
	if is_caught:
		return
	is_caught = true
	skip_turn = true
	is_catchable = false
	
	if sprite_2d:
		sprite_2d.texture = preload("res://art/pokeball.png")
	
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
