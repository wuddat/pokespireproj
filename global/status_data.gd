extends Node

const STATUS_LOOKUP := {
	"attack_up": preload("res://statuses/attack_up.tres"),
	"attack_down": preload("res://statuses/attack_down.tres"),
	"burned": preload("res://statuses/burned.tres"),
	"catching": preload("res://statuses/catching.tres"),
	"cleanse": preload("res://statuses/cleanse.tres"),
	"confused": preload("res://statuses/confused.tres"),
	"critical": preload("res://statuses/critical.tres"),
	"despair": preload("res://statuses/despair.tres"),
	"dexterity": preload("res://statuses/dexterity.tres"),
	"enraged": preload("res://statuses/enraged.tres"),
	"exposed": preload("res://statuses/exposed.tres"),
	"feeble": preload("res://statuses/feeble.tres"),
	"firespin": preload("res://statuses/firespin.tres"),
	"flinched": preload("res://statuses/flinched.tres"),
	"poisoned": preload("res://statuses/poisoned.tres"),
	"quiverdance": preload("res://statuses/quiverdance.tres"),
	"scaling": preload("res://statuses/scaling_per_turn.tres"),
	"seeded": preload("res://statuses/seeded.tres"),
	"sleep": preload("res://statuses/sleep.tres"),
}

func get_status_effects_from_ids(ids: Array[String]) -> Array[Status]:
	var effects: Array[Status] = []
	for id in ids:
		if STATUS_LOOKUP.has(id):
			effects.append(STATUS_LOOKUP[id].duplicate())
	return effects
