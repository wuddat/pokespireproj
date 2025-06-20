#player_handler.gd
class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.2

@export var hand: Hand
@export var player: Player

@onready var party_handler: PartyHandler = $"../PartyHandler"

var character: CharacterStats



func _ready() -> void:
	_establish_connections()



func start_battle(char_stats: CharacterStats) -> void:
	character = char_stats
	character.faint_pile.clear()
	
	character.battle_deck = character.build_battle_deck(party_handler.active_battle_party)
	character.draw_pile = character.battle_deck.duplicate(true)
	character.draw_pile.shuffle()
	
	for pkmn in character.current_party:
		if pkmn.health <= 0:
			#print("Exhausting cards for fainted Pokémon: %s (UID: %s)" % [pkmn.species_id, pkmn.uid])
			exhaust_cards_on_faint(pkmn.uid)

	character.discard = CardPile.new()
	_establish_connections()
	await get_tree().process_frame
	start_turn()


func start_turn() -> void:
	player.status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)
	character.block = 0
	character.reset_mana()
	
	var pkmn_with_turns = party_handler.get_active_pokemon_nodes()
	var pkmn_status_execution = pkmn_with_turns.duplicate()
	
	#print("pkmn_with_turns are: %s" % [pkmn_with_turns])
	if pkmn_with_turns.is_empty():
		# fallback, maybe just proceed
		return
	
	#TODO debug for determining acting_party_pokemon
	for pkmn in pkmn_with_turns:
		#print("STARTING TURN FOR:", pkmn.stats.species_id, "| BLOCK:", pkmn.stats.block)
		pkmn.start_of_turn()



func end_turn() -> void:
	hand.disable_hand()
	player.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)
	var pkmn_with_turns = party_handler.get_active_pokemon_nodes()
	var pkmn_status_execution = pkmn_with_turns.duplicate()

	if pkmn_status_execution.is_empty():
		# fallback, maybe just proceed
		return

	for pkmn in pkmn_status_execution:
		pkmn.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func draw_card() -> void:
	reshuffle_deck_from_discard()
	hand.add_card(character.draw_pile.draw_card())
	reshuffle_deck_from_discard()


func draw_cards(amount: int) -> void:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	
	tween.finished.connect(
		func(): Events.player_hand_drawn.emit()
	)


func discard_cards() -> void:
	if hand.get_child_count() == 0:
		Events.player_hand_discarded.emit()
		return
	
	var tween := create_tween()
	for card_ui in hand.get_children():
		tween.tween_callback(character.discard.add_card.bind(card_ui.card))
		tween.tween_callback(hand.discard_card.bind(card_ui))
		tween.tween_interval(HAND_DISCARD_INTERVAL)
		
	tween.finished.connect(
		func():
			Events.player_hand_discarded.emit()
	)


func reshuffle_deck_from_discard() -> void:
	if not character.draw_pile.empty():
		return
	
	while not character.discard.empty():
		character.draw_pile.add_card(character.discard.draw_card())
	
	character.draw_pile.shuffle()


func exhaust_cards_on_faint(uid: String) -> void:
	if not character.faint_pile.has(uid):
		character.faint_pile[uid] = CardPile.new()
	
	var cards_to_exhaust := CardPile.new()

	for card: Card in character.draw_pile.cards:
		if card.pkmn_owner_uid == uid:
			cards_to_exhaust.add_card(card)
	character.draw_pile.cards = character.draw_pile.cards.filter(
		func(c): return c.pkmn_owner_uid != uid
	)

	for card_ui in hand.get_children():
		if card_ui.card.pkmn_owner_uid == uid:
			cards_to_exhaust.add_card(card_ui.card)
			hand.discard_card(card_ui)
			draw_card()
			
			

	for card: Card in character.discard.cards:
		if card.pkmn_owner_uid == uid:
			cards_to_exhaust.add_card(card)
	character.discard.cards = character.discard.cards.filter(
		func(c): return c.pkmn_owner_uid != uid
	)
	
	for card_ui in hand.get_children():
		if card_ui.card.pkmn_owner_uid == uid:
			cards_to_exhaust.add_card(card_ui.card)
			hand.discard_card(card_ui)

	for card in cards_to_exhaust.cards:
		character.faint_pile[uid].add_card(card)

	character.draw_pile.shuffle()
	
	#print("Exhausted %d cards for fainted/switched pokemon: %s" % [cards_to_exhaust.cards.size(), uid])
	#print("The faint_pile is currently: ", character.faint_pile)


func restore_fainted_cards(uid: String) -> void:
	if not character.faint_pile.has(uid):
		return
	
	var pile: CardPile = character.faint_pile[uid]
	if pile.empty():
		return

	for card in pile.cards:
		character.draw_pile.add_card(card)
	
	character.faint_pile.erase(uid)
	#print("Restored %d cards for revived pokemon: %s" % [pile.cards.size(), uid])


func _on_card_played(card: Card) -> void:
	if card.exhausts or card.type == Card.Type.POWER:
		return
	if card.id == "nightshade":
		character.discard.add_card(card)
		character.discard.add_card(card)
		return
	else:
		character.discard.add_card(card)


func _on_statuses_applied(type: Status.Type) -> void:
	match type:
		Status.Type.START_OF_TURN:
			draw_cards(character.cards_per_turn)
		Status.Type.END_OF_TURN:
			discard_cards()


#func _on_pokemon_start_status_applied(pkmn: PokemonBattleUnit) -> void:



#func _on_pokemon_end_status_applied(pkmn: PokemonBattleUnit) -> void:



func _on_party_pokemon_fainted(unit: PokemonBattleUnit) -> void:
	var uid :=unit.stats.uid
	exhaust_cards_on_faint(uid)

func _on_party_pokemon_switch_requested(uid_out: String, uid_in: String) -> void:
	exhaust_cards_on_faint(uid_out)
	var switched_pkmn_cards_to_add := CardPile.new()
	var player_deck := character.deck.duplicate(true)
	for card: Card in player_deck.cards:
		if card.pkmn_owner_uid == uid_in:
			switched_pkmn_cards_to_add.add_card(card)
	for card in switched_pkmn_cards_to_add.cards:
		character.draw_pile.add_card(card)
	character.draw_pile.shuffle()


func _on_evolution_triggered(pkmn: PokemonBattleUnit) -> void:
	hand.disable_hand()

func _on_evolution_completed() -> void:
	hand.enable_hand()

func _establish_connections() -> void:
	if not Events.card_played.is_connected(_on_card_played):
		Events.card_played.connect(_on_card_played)
	if not Events.evolution_triggered.is_connected(_on_evolution_triggered):
		Events.evolution_triggered.connect(_on_evolution_triggered)
	if not Events.evolution_completed.is_connected(_on_evolution_completed):
		Events.evolution_completed.connect(_on_evolution_completed)
		
	#if not Events.player_pokemon_start_status_applied.is_connected(_on_pokemon_start_status_applied):
		#Events.player_pokemon_start_status_applied.connect(_on_pokemon_start_status_applied)
		#
	#if not Events.player_pokemon_end_status_applied.is_connected(_on_pokemon_end_status_applied):
		#Events.player_pokemon_end_status_applied.connect(_on_pokemon_end_status_applied)
		
	if not player.status_handler.statuses_applied.is_connected(_on_statuses_applied):
		player.status_handler.statuses_applied.connect(_on_statuses_applied)
		
	if not Events.party_pokemon_fainted.is_connected(_on_party_pokemon_fainted):
		Events.party_pokemon_fainted.connect(_on_party_pokemon_fainted)
	
	if not Events.player_pokemon_switch_requested.is_connected(_on_party_pokemon_switch_requested):
		Events.player_pokemon_switch_requested.connect(_on_party_pokemon_switch_requested)
