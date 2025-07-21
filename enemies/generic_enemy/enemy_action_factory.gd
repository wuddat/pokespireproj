# enemy_action_factory.gd
class_name EnemyActionFactory
extends RefCounted

static func create_action(category: String, move_data: Dictionary) -> BaseEnemyAction:
	var action_class = _get_action_class(category)
	if not action_class:
		push_warning("Unknown move category: " + category)
		return null
		
	var action = action_class.new()
	action.script_type = category
	action.setup_from_data(move_data)
	return action

static func _get_action_class(category: String):
	match category:
		"attack":
			return EnemyAttackAction
		"block":
			return EnemyBlockAction
		"status":
			return EnemyStatusAction
		_:
			return null
