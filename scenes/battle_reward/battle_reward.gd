class_name BattleReward
extends Control

const CARD_REWARDS = preload("res://scenes/ui/card_rewards.tscn")
const REWARD_BUTTON = preload("res://scenes/ui/reward_button.tscn")
const GOLD_ICON := preload("res://art/gold.png")
const GOLD_TEXT := "%s gold"
const CARD_ICON := preload("res://art/rarity.png")
const CARD_TEXT := "Add New Card"
const CAUGHT_ICON := preload("res://art/pokeball.png")
const CAUGHT_TEXT := "Pkmn Captured!"

const COINGAIN = preload("res://art/sounds/sfx/coingain.wav")
const REWARD_POP = preload("res://art/sounds/sfx/pokeball5.wav")
const PING_SOUND := preload("res://art/sounds/sfx/pc_menu_select.wav")
const PC_LOGOFF = preload("res://art/sounds/sfx/pc_logoff.wav")


@export var battle_stats: BattleStats
@export var run_stats: RunStats
@export var character_stats: CharacterStats
@export var caught_pokemon: Array[PokemonStats] = []
@export var leveled_pkmn_in_battle: Array[PokemonStats] = []
@export var gold_reward: int = 0

@onready var back_button: Button = $VBoxContainer/BackButton
@onready var rewards: VBoxContainer = %Rewards
var generated_rewards: Array[Control] = []

var card_reward_total_weight := 0.0
var card_rarity_weights := {
	Card.Rarity.COMMON: 0.0,
	Card.Rarity.UNCOMMON: 0.0,
	Card.Rarity.RARE: 0.0,
}


func _ready() -> void:
	for node: Node in rewards.get_children():
		node.queue_free()
	back_button.disabled = true


func add_gold_reward(amount: int) -> void:
	var gold_rew := REWARD_BUTTON.instantiate() as RewardButton
	gold_rew.reward_icon = GOLD_ICON
	gold_rew.reward_text = GOLD_TEXT % amount
	gold_rew.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_rew)
	back_button.disabled = true


func add_card_reward() -> void:
	var card_reward := REWARD_BUTTON.instantiate() as RewardButton
	card_reward.reward_icon = CARD_ICON
	card_reward.reward_text = CARD_TEXT
	card_reward.pressed.connect(_show_card_rewards)
	rewards.add_child.call_deferred(card_reward)

func add_random_item_reward() -> void:
	var item_reward := REWARD_BUTTON.instantiate() as RewardButton
	var random_item := ItemData.get_random_item()
	item_reward.reward_icon = random_item.icon
	item_reward.reward_text = "You found %s!" % random_item.name.capitalize()
	item_reward.pressed.connect(_on_item_reward_taken.bind(random_item))
	rewards.add_child.call_deferred(item_reward)


func add_item_reward(itm: String) -> void:
	var item_reward := REWARD_BUTTON.instantiate() as RewardButton
	var item := ItemData.build_item(itm)
	item_reward.reward_icon = item.icon
	item_reward.reward_text = "You found %s!" % item.name.capitalize()
	item_reward.pressed.connect(_on_item_reward_taken.bind(item))
	rewards.add_child.call_deferred(item_reward)


func add_pkmn_reward(pk: PokemonStats) -> void:
	print("Caught Pokémon array:", caught_pokemon)
	print("Caught Pokémon count:", caught_pokemon.size())
	var pkmn_reward := REWARD_BUTTON.instantiate()
	pkmn_reward.reward_icon = pk.icon
	pkmn_reward.reward_text = "Caught: %s " % pk.species_id.capitalize()
	pkmn_reward.pressed.connect(_on_pokemon_reward_taken.bind(pk))
	rewards.add_child.call_deferred(pkmn_reward)
	print("Reward button added for:", pk.species_id)

func add_leveled_pkmn_rewards(pkmn_stats: Array[PokemonStats]) -> void:
		var card_reward := REWARD_BUTTON.instantiate() as RewardButton
		card_reward.reward_icon = pkmn_stats[0].icon
		card_reward.reward_text = "%s Reached LVL %s!" % [pkmn_stats[0].species_id.capitalize(), pkmn_stats[0].level]
		card_reward.pressed.connect(_show_leveled_card_rewards.bind(str(pkmn_stats[0].uid)))
		rewards.add_child.call_deferred(card_reward)


func _show_leveled_card_rewards(pkmn_uid: String) -> void:
	if not run_stats or not character_stats:
		return

	SFXPlayer.play(PING_SOUND, true)

	var card_rewards := CARD_REWARDS.instantiate() as CardRewards
	add_child(card_rewards)
	card_rewards.card_reward_selected.connect(_on_card_reward_taken)
	var card_reward_array: Array[Card] = []
	var available_cards: Array[Card] = character_stats.draftable_cards.cards.duplicate(true)

	print("📛 Looking for cards owned by UID:", pkmn_uid)
	for card in available_cards:
		print("🔍 Card UID:", card.pkmn_owner_uid)

	# Filter by Pokémon UID
	available_cards = available_cards.filter(func(c): return c.pkmn_owner_uid == pkmn_uid)
	print("✅ Filtered cards:", available_cards.size())

	if available_cards.is_empty():
		print("❌ No cards found for this Pokémon.")
		return

	# 👇 Clamp rewards to how many valid cards we have
	var max_rewards = min(run_stats.card_rewards, available_cards.size())

	for i in max_rewards:
		_setup_card_chances()
		var roll := randf_range(0.0, card_reward_total_weight)

		for rarity: Card.Rarity in card_rarity_weights:
			if card_rarity_weights[rarity] > roll:
				_modify_weights(rarity)
				var picked_card := _get_random_available_card(available_cards, rarity)

				if picked_card != null:
					print("🎯 Picked Card:", picked_card)
					card_reward_array.append(picked_card)
					available_cards.erase(picked_card)
				else:
					print("⚠️ No card of rolled rarity, picking random fallback")
					if not available_cards.is_empty():
						picked_card = available_cards.pick_random()
						card_reward_array.append(picked_card)
						available_cards.erase(picked_card)
				break

	print("🎁 Final Card Reward Array:")
	for card in card_reward_array:
		Utils.print_resource(card)

	card_rewards.rewards = card_reward_array
	card_rewards.show()


func _show_card_rewards() -> void:
	if not run_stats or not character_stats:
		return
	
	var card_rewards := CARD_REWARDS.instantiate() as CardRewards
	add_child(card_rewards)
	card_rewards.card_reward_selected.connect(_on_card_reward_taken)
	
	var card_reward_array: Array[Card] = []
	var available_cards: Array [Card] = character_stats.draftable_cards.cards.duplicate(true)
	
	for i in run_stats.card_rewards:
		_setup_card_chances()
		var roll := randf_range(0.0, card_reward_total_weight)
		
		for rarity: Card.Rarity in card_rarity_weights:
			if card_rarity_weights[rarity] > roll:
				_modify_weights(rarity)
				var picked_card := _get_random_available_card(available_cards, rarity)
				
				if picked_card != null:
					print("picked Card" , picked_card, picked_card)
					card_reward_array.append(picked_card)
					available_cards.erase(picked_card)
				else:
					print("picked Card" , picked_card, picked_card)
					picked_card = available_cards.pick_random()
					card_reward_array.append(picked_card)
				break
	print("Cards in reward array are: ")
	for card in card_reward_array:
		Utils.print_resource(card)
	card_rewards.rewards = card_reward_array
	card_rewards.show()


func _setup_card_chances() -> void:
	card_reward_total_weight = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight
	card_rarity_weights[Card.Rarity.COMMON] = run_stats.common_weight
	card_rarity_weights[Card.Rarity.UNCOMMON] = run_stats.common_weight + run_stats.uncommon_weight
	card_rarity_weights[Card.Rarity.RARE] = card_reward_total_weight


func _modify_weights(rarity_rolled: Card.Rarity) -> void:
	if rarity_rolled == Card.Rarity.RARE:
		run_stats.rare_weight = RunStats.BASE_RARE_WEIGHT
	else:
		run_stats.rare_weight = clampf(run_stats.rare_weight +0.3, run_stats.BASE_RARE_WEIGHT, 5.0)


func _get_random_available_card(available_cards: Array[Card], with_rarity: Card.Rarity) -> Card:
	var all_possible_cards := available_cards.filter(
		func(card: Card):
			return card.rarity == with_rarity
	)
	return all_possible_cards.pick_random()


func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return
	SFXPlayer.play(COINGAIN)
	run_stats.gold += amount
	back_button.disabled = false
	


func _on_card_reward_taken(card: Card) -> void:
	if not character_stats or not card:
		return
	character_stats.deck.add_card(card)
	back_button.disabled = false

func _on_item_reward_taken(item: Item) -> void:
	if not character_stats or not item:
		return
	
	var has_duplicate := character_stats.item_inventory.items.any(func(itm): return itm.id == item.id)
	
	if character_stats.item_inventory.size() < 3 or has_duplicate:
		character_stats.item_inventory.add_item(item)
		print("Added %s to player inventory" % item.name)
		back_button.disabled = false
	else: SFXPlayer.pitch_play(PC_LOGOFF)

func _on_pokemon_reward_taken(stats: PokemonStats) -> void:
	if not character_stats:
		return
	var new_pokemon_stats := PokemonStats.from_enemy_stats(stats)
	var pkmn_to_add = Pokedex.create_pokemon_instance(new_pokemon_stats.species_id)
	Events.added_pkmn_to_party.emit(pkmn_to_add)
	await get_tree().process_frame
	Events.pokemon_reward_requested.emit(pkmn_to_add)
	back_button.disabled = false


func _on_back_button_pressed() -> void:
	SFXPlayer.play(PING_SOUND, true)
	Events.battle_reward_exited.emit()



func _play_reward_sequence() -> void:
	await _reward_delay()
	
	if leveled_pkmn_in_battle.size() > 0:
		for pkmn in leveled_pkmn_in_battle:
			add_leveled_pkmn_rewards([pkmn])
			await _reward_delay()
			
	if caught_pokemon.size() > 0:
		for pk in caught_pokemon:
			add_pkmn_reward(pk)
			await _reward_delay()
	
	
	add_gold_reward(gold_reward)
	await _reward_delay()
	
	var rand_amt: int
	if battle_stats.is_trainer_battle:
		rand_amt = randi_range(1,2)
	else: rand_amt = randi_range(0,1)
	
	for i in rand_amt:
		add_random_item_reward()
		await _reward_delay()
	
	var item_amt = randi_range(1,2)
	for i in item_amt:
		add_item_reward("pokeball")
		await _reward_delay()


func _reward_delay(duration := 0.6) -> void:
	SFXPlayer.play(REWARD_POP)
	await get_tree().create_timer(duration).timeout

#func update_caught_pkmn(caughtpkmn) -> void:
	#print("update_caught_pkmn_stack")
	#print_stack()
	#caught_pokemon = caughtpkmn
	#for pkmn in caught_pokemon:
		#print("dis be caught, 'mon:")
		#print(pkmn.species_id)
	#
	#call_deferred("_play_reward_sequence")
