#enemy_action.gd
class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0
@export var action_name: String
@export var intent_type: String


@onready var accumulated_weight := 0.0

var enemy
var target: Node
var targets = []


var confused_icon = preload("res://art/statuseffects/confused-effect.png")


func is_performable() -> bool:
	return false
	
	
func perform_action() -> void:
		pass


func update_intent_text() -> void:
	print("ENEMY_ACTION.GD update_intent_text called for action:", self)
	if not is_instance_valid(target):
		return

	intent.current_text = intent.base_text
	if enemy.status_handler.has_status("confused"):
		print("ENEMY_ACTION.GD 😵 Enemy is confused, setting confused icon.")
		intent.icon = confused_icon
		intent.current_text = ""  # or damage fallback
		intent.target = confused_icon
		return

	var target_pkmn := target
	print("ENEMY_ACTION.GD current target  in enemy_action.gd: ", target_pkmn.stats.species_id)


func animate_to_targets(
	targets_to_hit: Array[Node],
	index: int,
	total_damage: int,
	splash_damage: int,
	status_effects: Array[Status],
	self_damage: int,
	self_heal: int,
	self_status: Array[Status],
	enemy,
	damage_type: String,
	shift_enabled: int
) -> void:
	if index >= targets_to_hit.size():
		_execute_self_effects(enemy, total_damage, self_damage, self_heal, self_status)
		Events.enemy_action_completed.emit(enemy)
		return

	target = targets_to_hit[index]
	if not is_instance_valid(target):
		animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy, damage_type, shift_enabled)
		return

	var start_pos
	var end_pos
	
	if shift_enabled > 0:
		var shift_effect := ShiftEffect.new()
		shift_effect.tree = enemy.get_tree()
		shift_effect.amount = shift_enabled
		await shift_effect.execute([target])

	if total_damage <= 0:
		start_pos = enemy.global_position
		end_pos = enemy.global_position + Vector2.LEFT * 32
	else:
		start_pos = enemy.global_position
		end_pos = target.global_position + Vector2.RIGHT * 32

	var tween = create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(enemy, "global_position", end_pos, 0.3)

	if target.has_method("dodge_check") and target.dodge_check():
		_handle_dodge(tween, enemy, start_pos, func():
			animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy, damage_type, shift_enabled)
		)
	else:
		_handle_hit(tween, enemy, target, targets_to_hit, total_damage, splash_damage, status_effects, damage_type, start_pos, func():
			animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy, damage_type, shift_enabled), shift_enabled
		)


func _execute_self_effects(enemy, total_damage: int, self_damage: int, self_heal: int, self_status: Array[Status]) -> void:
	if self_damage > 0:
		var recoil := DamageEffect.new()
		recoil.amount = self_damage
		recoil.execute([enemy])

	if self_heal > 0:
		var heal := HealEffect.new()
		heal.amount = round(total_damage / 2)
		heal.execute([enemy])

	for effect in self_status:
		if effect:
			var status := StatusEffect.new()
			status.source = enemy
			status.status = effect.duplicate()
			status.execute([enemy])


func _handle_dodge(tween: Tween, enemy, start_pos: Vector2, on_finish: Callable) -> void:
	print("Attack was DODGED")
	tween.tween_interval(0.2)
	tween.tween_property(enemy, "global_position", start_pos, 0.3)
	tween.finished.connect(on_finish)


func _handle_hit(
	tween: Tween,
	enemy,
	target,
	targets_to_hit: Array[Node],
	total_damage: int,
	splash_damage: int,
	status_effects: Array[Status],
	damage_type: String,
	start_pos: Vector2,
	on_finish: Callable,
	shift_enabled: int,
) -> void:
	var dmg := DamageEffect.new()
	if intent_type != "status":
		var mult := TypeChart.get_multiplier(damage_type, target.stats.type)
		dmg.amount = round(total_damage * mult)
		dmg.sound = sound

	tween.tween_callback(func():
		if intent_type != "status":
			if dmg.amount > 0:
				dmg.execute([target])
				dmg.sound = sound
		
		if shift_enabled > 0 and targets_to_hit.size() > 0:
			pass
			#var shift_effect := ShiftEffect.new()
			#shift_effect.tree = enemy.get_tree()
			#shift_effect.amount = shift_enabled
			#shift_effect.execute([target])
		
		# Splash damage to others
		for splash_target in targets_to_hit:
			if splash_target != target:
				var splash := DamageEffect.new()
				splash.amount = splash_damage
				splash.execute([splash_target])

		# Status effects
		for status in status_effects:
			if status:
				var stat := StatusEffect.new()
				stat.source = enemy
				stat.status = status.duplicate()
				stat.sound = sound
				stat.execute([target])
	)

	tween.tween_interval(0.2)
	tween.tween_property(enemy, "global_position", start_pos, 0.3)
	tween.finished.connect(on_finish)
