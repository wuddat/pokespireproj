class_name Hand
extends HBoxContainer

@export var player: Player
@export var char_stats: CharacterStats
@export var party_handler: PartyHandler

@onready var card_ui := preload("res://scenes/card_ui/card_ui.tscn")

	
func add_card(card: Card) -> void:
	var new_card_ui := card_ui.instantiate()
	add_child(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	
	if card.pkmn_owner_uid == "":
		new_card_ui.player_pkmn_modifiers = player.modifier_handler
	if card.pkmn_owner_uid  != "":
		await _assign_modifiers_when_battle_pkmn_ready(new_card_ui, card.pkmn_owner_uid)
	


func discard_card(card: CardUI) -> void:
	card.queue_free()


func disable_hand() -> void:
	for card in get_children():
		card.disabled = true


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	
	child.reparent(self)
	var new_index := clampi(child.original_index, 0, get_child_count())
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)


func _assign_modifiers_when_battle_pkmn_ready(card_ui: CardUI, uid: String) -> void:
	await get_tree().process_frame
	
	var tries := 0
	while tries < 10:
		var unit := party_handler.get_pkmn_by_uid(uid)
		if unit != null:
			card_ui.battle_unit_owner = unit
			card_ui.player_pkmn_modifiers = unit.modifier_handler
			return
		await get_tree().create_timer(.1).timeout
		tries +=1
	
	push_warning("Couldn't find pkmnnbattleunits for card uid")
