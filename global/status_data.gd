extends Node

const STATUS_LOOKUP := {
	"poisoned": preload("res://statuses/poisoned.tres"),
	"enraged": preload("res://statuses/enraged.tres"),
	"exposed": preload("res://statuses/exposed.tres"),
	"attack_power": preload("res://statuses/attack_power.tres"),
	"catching": preload("res://statuses/catching.tres"),
	"burned": preload("res://statuses/burned.tres"),
	"flinched": preload("res://statuses/flinched.tres")
}

func get_status_effects_from_ids(ids: Array[String]) -> Array[Status]:
	var effects: Array[Status] = []
	for id in ids:
		if STATUS_LOOKUP.has(id):
			effects.append(STATUS_LOOKUP[id].duplicate())
	return effects
