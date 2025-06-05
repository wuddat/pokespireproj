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


func is_performable() -> bool:
	return false
	
	
func perform_action() -> void:
		pass


func update_intent_text() -> void:
	intent.current_text = intent.base_text

func animate_to_targets(targets_to_hit: Array[Node], index: int, damage:int) -> void:
	if index >= targets_to_hit.size():
		# All done
		Events.enemy_action_completed.emit(enemy)
		return

	var target_node = targets_to_hit[index]
	if not is_instance_valid(target_node):
		animate_to_targets(targets_to_hit, index + 1, damage)
		return

	var start_pos = enemy.global_position
	var end_pos = target_node.global_position + Vector2.RIGHT * 32

	var tween = create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(enemy, "global_position", end_pos, 0.3)

	var damage_effect = DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.sound = sound

	tween.tween_callback(func(): damage_effect.execute([target_node]))
	tween.tween_interval(0.2)
	tween.tween_property(enemy, "global_position", start_pos, 0.3)

	tween.finished.connect(func():
		animate_to_targets(targets_to_hit, index + 1, damage)
	)
