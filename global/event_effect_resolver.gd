# event_effect_resolver.gd
extends Node

func apply(effects: Dictionary, char_stats: CharacterStats, run_stats: RunStats) -> void:
	for effect in effects:
		match effect:
			"remove_item":
				_remove_item(effects[effect], run_stats)
			"gain_card":
				_gain_card(effects[effect], char_stats)
			"gain_gold":
				_gain_gold(effects[effect], run_stats)
			"lose_hp":
				_lose_hp(effects[effect], char_stats)
			"gain_random_move_card":
				_gain_random_move_card(char_stats)


func _remove_item(item: String, run_stats: RunStats) -> void:
	if item == "pokeball" and run_stats.pokeballs > 0:
		run_stats.pokeballs -= 1

func _gain_card(card_id: String, char_stats: CharacterStats) -> void:
	var card := Utils.create_card(card_id)
	if card:
		char_stats.deck.add_card(card)

func _gain_gold(amount: int, run_stats: RunStats) -> void:
	run_stats.gold += amount

func _lose_hp(amount: int, char_stats: CharacterStats) -> void:
	char_stats.current_hp = max(char_stats.current_hp - amount, 0)
	char_stats.stats_changed.emit()

func _gain_random_move_card(char_stats: CharacterStats) -> void:
	var possible_cards: CardPile= char_stats.get_all_move_cards()
	if possible_cards.is_empty():
		return
	possible_cards.shuffle()
	char_stats.deck.add_card(possible_cards.cards[0])
