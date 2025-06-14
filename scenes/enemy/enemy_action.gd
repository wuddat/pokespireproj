#enemy_action.gd
class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0

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
		intent.current_text = str(0)  # or damage fallback
		intent.target = confused_icon
		return

	var target_pkmn := target
	print("ENEMY_ACTION.GD current target  in enemy_action.gd: ", target_pkmn.stats.species_id)


func animate_to_targets(targets_to_hit: Array[Node], index: int, damage:int, status_effects:Array[Status]) -> void:
	if index >= targets_to_hit.size():
		# All done
		Events.enemy_action_completed.emit(enemy)
		return

	var target_node = targets_to_hit[index]
	if not is_instance_valid(target_node):
		animate_to_targets(targets_to_hit, index + 1, damage, status_effects)
		return

	var start_pos = enemy.global_position
	var end_pos = target_node.global_position + Vector2.RIGHT * 32

	var tween = create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(enemy, "global_position", end_pos, 0.3)

	var damage_effect = DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.sound = sound
	
	if status_effects.size() > 0:
		for status_effect in status_effects:
			if status_effect:
				var stat_effect := StatusEffect.new()
				var status_to_apply := status_effect.duplicate()
				stat_effect.status = status_to_apply
				stat_effect.execute([target_node])
	

	tween.tween_callback(func(): damage_effect.execute([target_node]))
	tween.tween_interval(0.2)
	tween.tween_property(enemy, "global_position", start_pos, 0.3)

	tween.finished.connect(func():
		animate_to_targets(targets_to_hit, index + 1, damage, status_effects)
	)
