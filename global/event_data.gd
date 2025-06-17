# event_data.gd
extends Node

var events := {
	"move_tutor": {
		"description": "An expert offers to teach your Pokémon a rare move of their specialty.",
		"dynamic_choices": true,
		"special_type": "move_tutor"
	},
	"imbued_stone": {
		"description": "You find a strange stone glowing faintly with the symbol for TYPE...",
		"dynamic_choices": true,
		"special_type": "imbued_stone"
	},
	"tm_found": {
		"description": "You stumble upon a TM...",
		"dynamic_choices": true,
		"special_type": "tm"
	},
	"strange_man": {
		"description": "You stumble upon a mysterious man offering you a rare Pokémon...",
		"choices": [
			{
				"text": "Pay 20% of your gold.",
				"effects": {
					"add_pokemon": "magikarp",
					"gold_percent_cost": 20
				}
			},
			{
				"text": "Walk away",
				"effects": {}
			}
		]
	}
}

func get_random_event_id() -> String:
	var keys := events.keys()
	keys.shuffle()
	return keys[0]

func get_event(id: String) -> Dictionary:
	return events.get(id, {})
