class_name Room
extends Resource

enum Type {NOT_ASSIGNED, MONSTER, TREASURE, POKECENTER, SHOP, BOSS, EVENT, TRAINER, LEGENDARY}

@export var type: Type
@export var row: int
@export var column: int
@export var position: Vector2
@export var next_rooms: Array[Room]
@export var selected := false
# only used for MONSTER TRAINER BOSS LEGENDARY types
@export var battle_stats: BattleStats
@export var tier: int = 0


func _to_string() -> String:
	return "%s (%s)" % [column, Type.keys()[type][0]]
