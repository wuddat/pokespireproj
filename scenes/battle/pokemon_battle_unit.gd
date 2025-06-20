#pokemon_battle_unit.gd
class_name PokemonBattleUnit
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")
const COMBAT_TEXT := preload("res://scenes/ui/combat_text_label.tscn")

@export var stats: PokemonStats : set = set_pokemon_stats
@export var spawn_position: String

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var health_bar_ui: HealthBarUI
var _queued_health_bar_ui: HealthBarUI = null

var skip_turn = false
var has_slept = false

func _ready() -> void:
	status_handler.status_owner = self
	status_handler.statuses_applied.connect(_on_statuses_applied)
	
	if not Events.enemy_seeded.is_connected(_on_enemy_seeded_turn_start):
		Events.enemy_seeded.connect(_on_enemy_seeded_turn_start)
	
	if not Events.evolution_completed.is_connected(_on_evolution_completed):
		Events.evolution_completed.connect(_on_evolution_completed)
	
	if _queued_health_bar_ui != null:
		set_health_bar_ui(_queued_health_bar_ui)
		
	##status effect testing
	#var status := preload("res://statuses/attack_down.tres")
	#var status1 := preload("res://statuses/attack_up.tres")
	#var status2 := preload("res://statuses/attack_up.tres")
	#var status3 := preload("res://statuses/burned.tres")
	#status_handler.add_status(status)
	#status_handler.add_status(status1)
	#status_handler.add_status(status2)
	#status_handler.add_status(status3)


func start_of_turn():
	#print(">>> START OF TURN CALLED FOR:", stats.species_id, "| Current Block:", stats.block)
	#print("status_handler valid? ", is_instance_valid(status_handler))

	stats.block = 0
	status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)
	#print(">>> END OF TURN LOGIC FOR:", stats.species_id, "| Block After Reset:", stats.block)

func _on_evolution_completed() -> void:
	Utils.print_resource(self.stats)

func set_pokemon_stats(value: PokemonStats) -> void:
	stats = value
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	update_pokemon()

func update_pokemon() -> void:
	if not stats is PokemonStats: return
	if not is_inside_tree(): await ready
	
	sprite_2d.texture = stats.art
	update_stats()

func update_stats() -> void:
	stats_ui.update_stats(stats)

func gain_block(block: int, mod_type:Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start := self.global_position
	var up_position := start + Vector2(0, -10)
	tween.tween_property(self, "position", up_position, 0.1)
	tween.tween_property(self, "position", start, 0.1)
	tween.tween_callback(stats.gain_block.bind(block))
	tween.tween_interval(0.17)

func take_damage(damage: int, mod_type: Modifier.Type) -> void:
	if stats.health <= 0: return

	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, mod_type)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 25, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	
	
	if modified_damage > 0:
		var dmg_text := COMBAT_TEXT.instantiate()
		add_child(dmg_text)
		dmg_text.show_text("%s" % modified_damage)
	
	tween.finished.connect(func():
		sprite_2d.material = null
		if stats.health <= 0:
			Events.party_pokemon_fainted.emit(self)
			hide()
	)
	
func heal(amount: int) -> void:
	if stats:
		var health_before := stats.health
		stats.heal(amount)
		var actual_heal := stats.health - health_before
		if actual_heal > 0:
			var heal_text := COMBAT_TEXT.instantiate()
			add_child(heal_text)
			heal_text.show_text("+ %s HP" % amount, Color.GREEN)
	
	

	# Optional: Add UI or feedback here
	print("%s healed for %d!" % [stats.species_id, amount])

func set_health_bar_ui(ui:HealthBarUI) -> void:
	if is_inside_tree() and is_instance_valid(status_handler):
		health_bar_ui = ui
		status_handler.set_status_ui_container(ui.status_container)
	else:
		_queued_health_bar_ui = ui  # Delay until ready

func _on_statuses_applied(type: Status.Type) -> void:
	if type == Status.Type.START_OF_TURN:
		Events.player_pokemon_start_status_applied.emit(self)
	elif type == Status.Type.END_OF_TURN:
		Events.player_pokemon_end_status_applied.emit(self)

func _on_enemy_seeded_turn_start(seeded: Status) -> void:
	heal(seeded.heal_strength)

func on_enemy_defeated(enemy: Enemy) -> void:
	var exp := enemy.stats.max_health * 2
	stats.current_exp += exp
	print("💥 Enemy defeated: %s | Gained EXP: %s" % [enemy.stats.species_id, exp])
	

	var text := COMBAT_TEXT.instantiate()
	add_child(text)
	text.show_text("EXP: %s" % exp)

	await get_tree().create_timer(0.4).timeout

	var level_up_exp := await stats.get_xp_for_next_level(stats.level)
	#print("level_up_exp: ", level_up_exp)
	
	if stats.current_exp >= level_up_exp:
		if stats.leveled_up_in_battle == false:
			stats.leveled_up_in_battle = true
			Events.add_leveled_pkmn_to_rewards.emit(stats)
		stats.level += 1
		#print("Leveling up!: ", stats.level)
		stats.max_health += stats.level
		stats.health += stats.level

		var level_text := COMBAT_TEXT.instantiate()
		add_child(level_text)
		level_text.show_text("LEVEL UP!")

		if stats.level >= stats.evolution_level:
			#print("Evolution TRIGGERED")
			Events.evolution_triggered.emit(self)

	await get_tree().process_frame  # Let evolution trigger finish
	if get_parent().has_node("EnemyHandler"):
		var enemy_handler = get_parent().get_node("EnemyHandler")
		if enemy_handler.get_child_count() == 0:
			await get_tree().process_frame
			await get_tree().create_timer(0.2).timeout
