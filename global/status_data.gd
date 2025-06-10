extends Node

const STATUS_LOOKUP := {
	"attack_power": preload("res://statuses/attack_power.tres"),
	"burned": preload("res://statuses/burned.tres"),
	"catching": preload("res://statuses/catching.tres"),
	"cleanse": preload("res://statuses/cleanse.tres"),
	"critical": preload("res://statuses/critical.tres"),
	"despair": preload("res://statuses/despair.tres"),
	"dexterity": preload("res://statuses/dexterity.tres"),
	"enraged": preload("res://statuses/enraged.tres"),
	"exposed": preload("res://statuses/exposed.tres"),
	"flinched": preload("res://statuses/flinched.tres"),
	"poisoned": preload("res://statuses/poisoned.tres"),
	"scaling": preload("res://statuses/scaling_per_turn.tres"),
}

func get_status_effects_from_ids(ids: Array[String]) -> Array[Status]:
	var effects: Array[Status] = []
	for id in ids:
		if STATUS_LOOKUP.has(id):
			effects.append(STATUS_LOOKUP[id].duplicate())
	return effects
