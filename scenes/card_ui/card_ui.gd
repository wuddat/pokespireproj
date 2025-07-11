class_name CardUI
extends Control

signal reparent_requested(which_card_ui: CardUI)

const BASE_CARDSTYLE := preload("res://scenes/card_ui/card_base_style.tres")
const DRAG_CARDSTYLE := preload("res://scenes/card_ui/card_dragging_style.tres")
const HOVER_CARDSTYLE := preload("res://scenes/card_ui/card_hover_style.tres")
const SNORE := preload("res://art/sounds/sfx/snore.mp3")

@export var card: Card : set = _set_card
@export var char_stats: CharacterStats : set = _set_char_stats
@export var player_pkmn_modifiers: ModifierHandler
@export var battle_unit_owner: PokemonBattleUnit
@export var party_handler: PartyHandler

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_visuals: CardVisuals = $CardVisuals
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_state_machine: CardStateMachine = $CardStateMachine as CardStateMachine
@onready var targets: Array[Node] = []
@onready var lead_overlay: ColorRect = %LeadOverlay

var play_card_delay: float = 0.4
var lead_tween: Tween = null
var pulse: Tween = null


var original_index := 0
var parent: Control
var tween: Tween
var playable := true : set = _set_playable
var disabled := false : set = _set_disabled


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
		#Events.card_play_completed.emit()
		queue_free()
		return

	var player_handler := get_node("/root/Run/CurrentView/Battle/PlayerHandler") as PlayerHandler
	var hand := get_node("/root/Run/CurrentView/Battle/BattleUI/Hand") as Hand
	if not player_handler:
		print("❌ PlayerHandler not found in scene tree.")
		#Events.card_play_completed.emit()
		queue_free()
		return

	var discard := player_handler.character.discard
	if discard.empty():
		print("❌ Discard pile is empty. Metronome fizzled!")
		#Events.card_play_completed.emit()
		queue_free()
		return

	# 🧬 Select a random card from discard
	var random_card := discard.cards[randi() % discard.cards.size()]
	print("🎲 Metronome selected:", random_card.id)

	discard.cards.erase(random_card)
	random_card.current_cost = 0
	hand.add_card(random_card)
	discard.add_card(card)
	#Events.card_play_completed.emit()
	queue_free()


func get_active_enemy_modifiers() -> ModifierHandler:
	if targets.is_empty() or targets.size() > 1:
		return null

	if not is_instance_valid(targets[0]) or not targets[0] is Enemy:
		return null

	return targets[0].modifier_handler


func request_tooltip() -> void:
	
	var enemy_modifiers := get_active_enemy_modifiers()
	if not is_instance_valid(player_pkmn_modifiers) or not is_instance_valid(enemy_modifiers) or not is_instance_valid(targets):
		is_instance_valid(player_pkmn_modifiers)
		is_instance_valid(enemy_modifiers)
		is_instance_valid(targets)
		var updated_tooltip := card.get_updated_tooltip(player_pkmn_modifiers, enemy_modifiers, targets)
		Events.card_tooltip_requested.emit(card.icon, updated_tooltip, card.pkmn_icon, card.name.capitalize())


func show_lead_effect() -> void:
	if not %LeadOverlay:
		push_warning("LeadOverlay not found!")
		return

	%LeadOverlay.visible = true
	%LeadOverlay.color.a = 0.2

	# Stop previous tween if still running
	if lead_tween and lead_tween.is_running():
		lead_tween.kill()

	# Create a new tween
	lead_tween = create_tween().set_loops()  # infinite looping
	lead_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	lead_tween.tween_property(%LeadOverlay, "modulate:a", 1, 0.6).from(0.2)
	lead_tween.tween_property(%LeadOverlay, "modulate:a", 0.2, 0.6)
	pulse = create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(self, "scale", Vector2(1.03, 1.03), 0.25).from(Vector2(1.0, 1.0))
	pulse.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)


func stop_lead_effect() -> void:
	if %LeadOverlay:
		%LeadOverlay.visible = false
	if lead_tween and lead_tween.is_running():
		lead_tween.kill()
		pulse.kill()

func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	#SFXPlayer.pitch_play(CARD_FLICK_1)
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


func _set_playable(value: bool) -> void:
	playable = value

	if card.pkmn_owner_uid != "" and is_instance_valid(party_handler):
		var unit := party_handler.get_pkmn_by_uid(card.pkmn_owner_uid)
		if unit and unit.status_handler.has_status("flinched"):
			playable = false
			disabled = true
			card_visuals.cost.modulate = Color.DARK_RED
			card_visuals.modulate.a = 0.5
			return

	disabled = false
	if not playable:
		card_visuals.cost.modulate = Color.DARK_RED
	else:
		card_visuals.cost.modulate = Color(1,1,1,1) if card.rarity == Card.Rarity.UNCOMMON else Color(0.213, 0.44, 1, 1)



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


func play_card_with_delay(crd: Card) -> void:
	hide()
	Events.card_played.emit(crd)
	char_stats.mana -= crd.current_cost
	crd.random_targets.clear()
	
	#handle confusion/paralysis if any:
	if await _sleep_check(crd):
		await get_tree().create_timer(0.2).timeout
	elif await _paralysis_check(crd):
		await get_tree().create_timer(0.2).timeout
	elif await _confusion_check(crd):
		_handle_confusion_self_hit(crd)
		await get_tree().create_timer(0.2).timeout
	
	else:
		# Handle randomplay roll
		if crd.randomplay > 0:
			crd.multiplay = randi_range(2, crd.randomplay)

		# Pre-select random targets if needed
		if crd.target == Card.Target.RANDOM_ENEMY:
			for i in range(crd.multiplay):
				crd.random_targets.append(crd._get_targets([], battle_unit_owner))

		print("[CARD_UI] Playing card %s %s times..." % [crd.name, crd.multiplay])

		# Play card with delays between
		if crd.multiplay > 1:
				Events.battle_text_requested.emit("Hit [color=red]%s[/color] times!" % crd.multiplay)
				await get_tree().create_timer(play_card_delay).timeout
		for i in range(crd.multiplay):
			if crd.is_single_targeted():
				if crd.target == Card.Target.RANDOM_ENEMY:
					crd.apply_effects(crd.random_targets[i], player_pkmn_modifiers, battle_unit_owner)
				elif crd.target == Card.Target.SPLASH:
					crd.apply_effects(crd._get_targets(targets, battle_unit_owner), player_pkmn_modifiers, battle_unit_owner)
				else:
					crd.apply_effects(targets, player_pkmn_modifiers, battle_unit_owner)
			else:
				crd.apply_effects(crd._get_targets(targets, battle_unit_owner), player_pkmn_modifiers, battle_unit_owner)

			await get_tree().create_timer(0.2).timeout


func _confusion_check(crd: Card) -> bool:
	if not is_instance_valid(battle_unit_owner):
		return false
	if not battle_unit_owner.status_handler.has_status("confused"):
		return false
	Events.battle_text_requested.emit("%s is CONFUSED!" % battle_unit_owner.stats.species_id.capitalize())
	await get_tree().create_timer(play_card_delay).timeout
	var chance := 0.3
	var roll := randf()
	if roll < chance:
		print("[CARD_UI] %s is confused and hits itself!" % battle_unit_owner.stats.species_id)
		return true
	var roll2 := randf()
	if roll2 > chance:
		Events.battle_text_requested.emit("%s snapped out of confusion!" % battle_unit_owner.stats.species_id.capitalize())
		await get_tree().create_timer(.6).timeout
		battle_unit_owner.status_handler.remove_status("confused")
		battle_unit_owner.unit_status_indicator.hide()
		Events.battle_text_requested.emit("%s used %s!" % [battle_unit_owner.stats.species_id.capitalize(), crd.name])
		print("[CARD_UI] %s snaps out of confusion." % battle_unit_owner.stats.species_id)
		return false
	else:
		Events.battle_text_requested.emit("%s used %s!" % [battle_unit_owner.stats.species_id.capitalize(), crd.name])
		print("[CARD_UI]✅ %s resists confusion and plays normally." % battle_unit_owner.stats.species_id)
		battle_unit_owner.unit_status_indicator.update_status_display(battle_unit_owner)
		return false


func _handle_confusion_self_hit(_card: Card) -> void:
	var damage: int = round(battle_unit_owner.stats.max_health * 0.2)
	print("pkmn to self hit is: %s" % battle_unit_owner.stats.species_id)
	print("damage to take is %s" % damage)
	Events.battle_text_requested.emit("%s hit itself in confusion for [color=red]%s[/color] damage!" % [battle_unit_owner.stats.species_id.capitalize(), damage])
	battle_unit_owner.status_handler.decrement_status("confused")
	var effect := DamageEffect.new()
	effect.amount = damage
	print("effect amount is: %s" % damage)
	effect.sound = preload("res://art/sounds/Tackle.wav")
	effect.execute([battle_unit_owner])
	print("damage effect executed on %s" % battle_unit_owner.stats.species_id)


func _paralysis_check(crd: Card) -> bool:
	if not is_instance_valid(battle_unit_owner):
		return false
	if not battle_unit_owner.status_handler.has_status("paralyze"):
		return false
	await get_tree().create_timer(play_card_delay).timeout
	var chance := 0.25
	var roll := randf()
	if roll < chance:
		print("%s is fully paralyzed!" % battle_unit_owner.stats.species_id)
		Events.battle_text_requested.emit("%s is PARALYZED!" % battle_unit_owner.stats.species_id.capitalize())
		SFXPlayer.play(preload("res://art/sounds/sfx/stat_paralyze.mp3"))
		var par_tween := create_tween()
		par_tween.tween_callback(Shaker.shake.bind(battle_unit_owner, 25, 0.15))
		par_tween.tween_interval(0.17)
		battle_unit_owner.status_handler.decrement_status("paralyze")
		return true
	Events.battle_text_requested.emit("%s used %s!" % [battle_unit_owner.stats.species_id.capitalize(), crd.name])
	print("✅ %s resists paralysis and plays normally." % battle_unit_owner.stats.species_id)
	return false


func _sleep_check(crd: Card) -> bool:
	if not is_instance_valid(battle_unit_owner):
		return false
	if not battle_unit_owner.is_asleep:
		return false

	Events.battle_text_requested.emit("%s is sleeping..." % battle_unit_owner.stats.species_id.capitalize())
	var slp_tween := create_tween()
	slp_tween.tween_callback(Shaker.shake.bind(battle_unit_owner, 15, 0.25))
	slp_tween.tween_interval(0.6)
	slp_tween.tween_callback(Shaker.shake.bind(battle_unit_owner, 15, 0.25))
	SFXPlayer.play(SNORE)
	await get_tree().create_timer(1).timeout

	var stuck_asleep := 0.4  # or whatever value feels right
	var roll := randf()
	if roll < stuck_asleep:
		slp_tween = create_tween()
		slp_tween.tween_callback(Shaker.shake.bind(battle_unit_owner, 25, 0.15))
		slp_tween.tween_interval(0.17)
		Events.battle_text_requested.emit("%s is fast asleep..!" % battle_unit_owner.stats.species_id.capitalize())
		return true
	else:
		Events.battle_text_requested.emit("%s woke up!" % battle_unit_owner.stats.species_id.capitalize())
		await get_tree().create_timer(play_card_delay).timeout
		battle_unit_owner.is_asleep = false
		battle_unit_owner.unit_status_indicator.hide()
		Events.battle_text_requested.emit("%s used %s!" % [battle_unit_owner.stats.species_id.capitalize(), crd.name])
		print("✅ %s woke up and plays normally." % battle_unit_owner.stats.species_id)
		return false



func _set_disabled(value: bool) -> void:
	disabled = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE if value else Control.MOUSE_FILTER_STOP
	# Optional: make it visually obvious
	modulate.a = 0.5 if value else 1.0
