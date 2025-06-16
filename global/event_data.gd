# event_data.gd
extends Node

var events := {
	"mysterious_statue": {
		"description": "You find a crumbling statue of an ancient Pokémon. It radiates a gentle warmth.",
		"choices": [
			{
				"text": "Offer a Pokéball",
				"effects": {
					"remove_item": "pokeball",
					"gain_card": "blessing_of_mew"
				}
			},
			{
				"text": "Leave it alone",
				"effects": {}
			}
		]
	},
	"ancient_book": {
		"description": "A dusty tome lies open. It speaks of forgotten techniques...",
		"choices": [
			{
				"text": "Study the book (-10 HP, gain random move card)",
				"effects": {
					"lose_hp": 10,
					"gain_random_move_card": true
				}
			},
			{
				"text": "Burn the book (gain gold)",
				"effects": {
					"gain_gold": 30
				}
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
