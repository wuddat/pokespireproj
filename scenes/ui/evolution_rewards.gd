class_name EvolutionReward
extends Control

@onready var cards_to_forget: VBoxContainer = %CardsToForget
@onready var cards_to_learn: VBoxContainer = %"Cards to Learn"
@onready var forget_slot: CardMenuUI = %ForgetCard
@onready var learn_slot: CardMenuUI = %"Learn Card"
@onready var confirm_button: Button = %ConfirmButton
@onready var sprite_2d: Sprite2D = $Sprite2D
@export var char_stats: CharacterStats

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")

var pokemon: PokemonStats
var player_deck: Array[Card]
var forget_card: Card = null
var learn_card: Card = null

func _ready() -> void:
	await self.ready
	self.z_index = 999  
	print("🟩 EvolutionReward _ready fired")

	if char_stats != null:
		print("⚠️ char_stats is _ready!")

func setup(pkmn: PokemonBattleUnit, deck: Array[Card], learn_options: Array[Card]) -> void:
	if not is_instance_valid(cards_to_forget):
		await get_tree().process_frame  # fallback if setup called too early

	print("📦 Setup called!")
	print("🎴 Deck count: %d" % deck.size())
	print("🧠 Learn options count: %d" % learn_options.size())

	pokemon = pkmn.stats
	player_deck = deck
	_populate_forget_cards()
	_populate_learn_cards(learn_options)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm)

func _populate_forget_cards() -> void:
	print("🧪 Populating forget cards...")
	for card in player_deck:
		print("🧬 Checking Card ID: ", card.id)
		print("🧬 Matching UID: ", card.pkmn_owner_uid)
		if card.pkmn_owner_uid == pokemon.uid:
			if card.id in _get_duplicate_ids(cards_to_forget):
				print("⛔ Already added: ", card.id)
				continue
			var card_ui = CARD_MENU_UI.instantiate()
			await card_ui.ready
			print("char_stats is: ", [char_stats], char_stats)
			card_ui.set_char_stats(char_stats)
			card_ui.set_card(card)
			card_ui.tooltip_requested.connect(_on_forget_selected)
			print("➕ Adding forget card: ", card.id)
			cards_to_forget.add_child(card_ui)
			print("✅ Added to forget UI")

func _populate_learn_cards(learn_cards: Array[Card]) -> void:
	for card in learn_cards:
		var card_ui = CARD_MENU_UI.instantiate()
		await card_ui.ready
		card_ui.set_char_stats(char_stats)
		card_ui.set_card(card)
		card_ui.tooltip_requested.connect(_on_learn_selected)
		cards_to_learn.add_child(card_ui)

func _on_forget_selected(card: Card) -> void:
	forget_card = card
	forget_slot.modulate = Color(1,1,1,1)
	forget_slot.set_char_stats(char_stats)
	forget_slot.set_card(card)

	_update_confirm_button()

func _on_learn_selected(card: Card) -> void:
	learn_card = card
	learn_slot.modulate = Color(1,1,1,1)
	learn_slot.set_char_stats(char_stats)
	learn_slot.set_card(card)
	_update_confirm_button()

func _on_confirm() -> void:
	print("\n--- BEFORE Replacement ---")
	_debug_print_deck("BEFORE")

	var replacements := []
	for card in player_deck:
		if card.id == forget_card.id and card.pkmn_owner_uid == pokemon.uid:
			replacements.append(card)

	for old_card in replacements:
		player_deck.erase(old_card)

	for _i in replacements:
		var new_card = learn_card.duplicate()
		player_deck.append(new_card)

	print("\n--- AFTER Replacement ---")
	_debug_print_deck("AFTER")

	queue_free()

func _get_duplicate_ids(container: VBoxContainer) -> Array[String]:
	var ids :Array[String] = []
	for node in container.get_children():
		if node is CardMenuUI:
			ids.append(node.card.id)
	return ids

func _update_confirm_button() -> void:
	confirm_button.disabled = forget_card == null or learn_card == null

func _debug_print_deck(label: String = "") -> void:
	print("--- Deck State (%s) ---" % label)
	for card in player_deck:
		print("• [%s] %s (UID: %s)" % [card.id, card.name, card.pkmn_owner_uid])
