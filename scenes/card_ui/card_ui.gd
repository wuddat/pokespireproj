class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

const BASE_CARDSTYLE := preload("res://scenes/card_ui/card_base_style.tres")
const DRAG_CARDSTYLE := preload("res://scenes/card_ui/card_dragging_style.tres")
const HOVER_CARDSTYLE := preload("res://scenes/card_ui/card_hover_style.tres")

@export var card: Card : set = _set_card
@export var char_stats: CharacterStats : set = _set_char_stats
@export var player_pkmn_modifiers: ModifierHandler

@export var battle_unit_owner: PokemonBattleUnit

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_visuals: CardVisuals = $CardVisuals
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_state_machine: CardStateMachine = $CardStateMachine as CardStateMachine
@onready var targets: Array[Node] = []



var original_index := 0
var parent: Control
var tween: Tween
var playable := true : set = _set_playable
var disabled := false


func _ready() -> void:
	Events.card_aim_started.connect(_on_card_drag_or_aiming_started)
	Events.card_drag_started.connect(_on_card_drag_or_aiming_started)
	Events.card_aim_ended.connect(_on_card_drag_or_aiming_ended)
	Events.card_drag_ended.connect(_on_card_drag_or_aiming_ended)
	card_state_machine.init(self)


func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)


func animate_to_position(new_position: Vector2, duration: float) -> void:
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)


func play() -> void:
	if not card:
		return
	
	Events.card_play_initiated.emit()
	if card.id != "metronome":
		await play_card_with_delay(card)
		Events.card_play_completed.emit()
		queue_free()
		return

	var player_handler := get_node("/root/Run/CurrentView/Battle/PlayerHandler") as PlayerHandler
	var hand := get_node("/root/Run/CurrentView/Battle/BattleUI/Hand") as Hand
	if not player_handler:
		print("❌ PlayerHandler not found in scene tree.")
		Events.card_play_completed.emit()
		queue_free()
		return

	var discard := player_handler.character.discard
	if discard.empty():
		print("❌ Discard pile is empty. Metronome fizzled!")
		Events.card_play_completed.emit()
		queue_free()
		return

	# 🧬 Select a random card from discard
	var random_card := discard.cards[randi() % discard.cards.size()]
	print("🎲 Metronome selected:", random_card.id)

	discard.cards.erase(random_card)
	random_card.cost = 0
	hand.add_card(random_card)
	discard.add_card(card)
	Events.card_play_completed.emit()
	queue_free()


func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty() or targets.size() > 1:
		return null

	if not is_instance_valid(targets[0]) or not targets[0] is Enemy:
		return null

	return targets[0].modifier_handler


func request_tooltip() -> void:
	var enemy_modifiers := get_active_enemy_modifiers()
	await get_tree().process_frame
	var updated_tooltip := card.get_updated_tooltip(player_pkmn_modifiers, enemy_modifiers, targets)
	Events.card_tooltip_requested.emit(card.icon, updated_tooltip, card.pkmn_icon, card.name.capitalize())


func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()
	


func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()


func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	if value == null:
		push_warning("_set_card was called with a null value. Skipping.")
		return
	card = value
	card_visuals.card = card


func _set_playable(value:bool) -> void:
	playable = value
	if not playable:
		card_visuals.cost.add_theme_color_override("font_color", Color.DARK_RED)
		card_visuals.icon.modulate = Color(1, 1, 1, 0.5)
	else:
		card_visuals.cost.remove_theme_color_override("font_color")
		card_visuals.icon.modulate = Color(1, 1, 1, 1)


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	card_visuals.set_char_stats(value)
	char_stats.stats_changed.connect(_on_char_stats_changed)


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)


func _on_card_drag_or_aiming_started(used_card: CardUI) -> void:
	#Events.tooltip_hide_requested.emit()
	if used_card == self:
		return
	
	disabled = true


func _on_card_drag_or_aiming_ended(_card: CardUI) -> void:
	disabled = false
	playable = char_stats.card_playable(card)


func _on_char_stats_changed() -> void:
	playable = char_stats.card_playable(card)


func play_card_with_delay(card: Card) -> void:
	Events.card_played.emit(card)
	char_stats.mana -= card.cost
	card.random_targets.clear()

	# Handle randomplay roll
	if card.randomplay > 0:
		card.multiplay = randi_range(2, card.randomplay)

	# Pre-select random targets if needed
	if card.target == Card.Target.RANDOM_ENEMY:
		for i in range(card.multiplay):
			card.random_targets.append(card._get_targets([], battle_unit_owner))

	print("🔁 Playing card %s %s times..." % [card.name, card.multiplay])

	# Play card with delays between
	for i in range(card.multiplay):
		if card.is_single_targeted():
			if card.target == Card.Target.RANDOM_ENEMY:
				card.apply_effects(card.random_targets[i], player_pkmn_modifiers, battle_unit_owner)
			elif card.target == Card.Target.SPLASH:
				card.apply_effects(card._get_targets(targets, battle_unit_owner), player_pkmn_modifiers, battle_unit_owner)
			else:
				card.apply_effects(targets, player_pkmn_modifiers, battle_unit_owner)
		else:
			card.apply_effects(card._get_targets(targets, battle_unit_owner), player_pkmn_modifiers, battle_unit_owner)

		await get_tree().create_timer(0.2).timeout
