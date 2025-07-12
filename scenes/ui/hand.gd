class_name Hand
extends Control

@export var player: Player
@export var char_stats: CharacterStats
@export var party_handler: PartyHandler
@export var player_handler: PlayerHandler

const CARD_SFX_1 = preload("res://art/sounds/sfx/card_sfx1.mp3")

@onready var card_ui := preload("res://scenes/card_ui/card_ui.tscn")
@onready var draw_pile_button: CardPileOpener = %DrawPileButton
@onready var discard_pile_button: CardPileOpener = %DiscardPileButton

var cards_played_this_turn: int = 0
var lead_enabled: bool = false
var hand_max: int = 5

func _ready():
	_establish_connections()

func add_card(card: Card) -> void:
	var total_hand: int = get_child_count()
	print("hand size is: ",total_hand)
	if total_hand >= hand_max:
		return
	var new_card_ui := card_ui.instantiate()
	
	add_child(new_card_ui)
	await get_tree().process_frame
	var spawn_position = new_card_ui.global_position
	new_card_ui.global_position = draw_pile_button.global_position + Vector2(0, -50)
	SFXPlayer.pitch_play(CARD_SFX_1)
	new_card_ui.animate_to_position(spawn_position, .2)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.card.base_card = card.duplicate(true)
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	new_card_ui.party_handler = party_handler
	new_card_ui.playable = true
	
	if lead_enabled and new_card_ui.card.lead_effects:
		new_card_ui.card.apply_lead_mods(card)
		new_card_ui.show_lead_effect()
	
	if card.pkmn_owner_uid == "":
		card.pkmn_icon = card.icon
		new_card_ui.card_visuals.owner_icon.scale = Vector2(.5,.5)
		new_card_ui.card_visuals.icon.hide()
		new_card_ui.card_visuals.effect.hide()
	
	if card.pkmn_owner_uid == null:
		return
	if card.pkmn_owner_uid == "":
		new_card_ui.player_pkmn_modifiers = player.modifier_handler
	if card.pkmn_owner_uid  != "":
		await _assign_modifiers_when_battle_pkmn_ready(new_card_ui, card.pkmn_owner_uid)
	


func discard_card(card: CardUI) -> void:
	SFXPlayer.pitch_play(CARD_SFX_1, 1.3, 1.35)
	card.animate_to_position(discard_pile_button.global_position, .2)
	await get_tree().create_timer(.3).timeout
	card.queue_free()


func disable_hand() -> void:
	for card in get_children():
		card.disabled = true
		

func enable_hand() -> void:
	for card in get_children():
		card.disabled = false


func refresh_leads_to_base() -> void:
	print("Cards played this turn: ", cards_played_this_turn)
	if cards_played_this_turn > 0:
		lead_enabled = false
		for child in get_children():
			var crd: Card = child.card
			if crd.base_card != null and crd.lead_effects:
				print("============PRINTING CARD BEFORE: =======================")
				Utils.print_resource(crd)
				crd = crd.base_card.duplicate(true)
				crd.base_card = crd
				child.card = crd
				child.stop_lead_effect()
				child.card_visuals._update_visuals()
				print("============PRINTING CARD AFTER: =======================")
				Utils.print_resource(crd)
				print("============PRINTING CARD BASE: =======================")
				Utils.print_resource(crd.base_card)


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	
	child.reparent(self)
	var new_index := clampi(child.original_index, 0, get_child_count())
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)


func _assign_modifiers_when_battle_pkmn_ready(cardui: CardUI, uid: String) -> void:
	await get_tree().process_frame
	
	var tries := 0
	while tries < 10:
		var unit := party_handler.get_pkmn_by_uid(uid)
		if unit != null:
			cardui.battle_unit_owner = unit
			cardui.player_pkmn_modifiers = unit.modifier_handler
			return
		await get_tree().create_timer(.1).timeout
		tries +=1
	
	push_warning("Couldn't find pkmnnbattleunits for card uid")

func _establish_connections() -> void:
	if not Events.card_play_initiated.is_connected(disable_hand):
		Events.card_play_initiated.connect(disable_hand)
	if not Events.card_play_completed.is_connected(enable_hand):
		Events.card_play_completed.connect(enable_hand)
