#enemy_action.gd
class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0
@export var action_name: String

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D
var targets: Array[PokemonBattleUnit] = []


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
	enemy: Node,
	damage_type: String
) -> void:
	if index >= targets_to_hit.size():
		# Cleanup effects after final target
		if self_damage > 0:
			var recoil := DamageEffect.new()
			recoil.amount = self_damage
			recoil.execute([enemy])

		if self_heal > 0:
			var heal := HealEffect.new()
			heal.amount = int(total_damage / 2)
			heal.execute([enemy])

		for self_effect in self_status:
			if self_effect:
				var status_instance := StatusEffect.new()
				status_instance.status = self_effect.duplicate()
				status_instance.execute([enemy])

		Events.enemy_action_completed.emit(enemy)
		return

	var target_node = targets_to_hit[index]
	if not is_instance_valid(target_node):
		animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy, damage_type)
		return
	var start_pos
	var end_pos
	if total_damage <= 0:
		start_pos = enemy.global_position
		end_pos = enemy.global_position + Vector2.LEFT * 32
	else:
		start_pos = enemy.global_position
		end_pos = target_node.global_position + Vector2.RIGHT * 32

	var tween = create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(enemy, "global_position", end_pos, 0.3)

	var dmg_effect := DamageEffect.new()
	var target_types = target_node.stats.type
	var mult = Effectiveness.get_multiplier(damage_type, target_types)
	dmg_effect.amount = round(total_damage * mult)
	dmg_effect.sound = sound

	tween.tween_callback(func():
		dmg_effect.execute([target_node])
		dmg_effect.sound = sound

		# Apply splash damage to other targets
		for splash_target in targets_to_hit:
			if splash_target != target_node:
				var splash := DamageEffect.new()
				var splash_amt := splash_damage
				splash.amount = splash_amt
				splash.execute([splash_target])

		# Apply statuses
		for status_effect in status_effects:
			if status_effect:
				var stat := StatusEffect.new()
				stat.status = status_effect.duplicate()
				stat.execute([target_node])
	)

	tween.tween_interval(0.2)
	tween.tween_property(enemy, "global_position", start_pos, 0.3)

	tween.finished.connect(func():
		animate_to_targets(targets_to_hit, index + 1, total_damage, splash_damage, status_effects, self_damage, self_heal, self_status, enemy, damage_type)
	)
