class_name EventScene
extends Control

@export var char_stats: CharacterStats
@export var run_stats: RunStats
@onready var description_label := $UILayer/UI/Description
@onready var choices_container := $UILayer/UI 
@onready var card_pile_view: CardPileView = $UILayer/CardPileView

const PC_MENU_SELECT = preload("res://art/sounds/sfx/pc_menu_select.wav")

var event_data := {}  # Loaded from JSON or hardcoded dictionary

func _ready():
	# Load a random event
	await get_tree().create_timer(0.1).timeout  
	
	var random_event_id = EventData.get_random_event_id()
	event_data = EventData.get_event(random_event_id)
	var special_type = event_data.get("special_type", "")
	
	match special_type:
		"move_tutor":
			var tutor_type = _pick_random_type()
			event_data["tutor_type"] = tutor_type
			description_label.text = "You find a move tutor specializing in %s-type moves. He offers to teach one to your Pokémon..." % tutor_type.capitalize()
		"tm":
			var tm_id = _pick_random_tm()
			event_data["tm_id"] = tm_id
			description_label.text = "You stumble upon a TM containing %s!" % tm_id.capitalize()
		"imbued_stone":
			var stone_type = _pick_random_type()
			event_data["stone_type"] = stone_type
			description_label.text = "You find a strange stone glowing faintly with the symbol for %s..." % stone_type.capitalize()
		"hypno_trance":
			var random_pkmn = char_stats.get_all_party_members()
			random_pkmn.shuffle()
			event_data["target_pokemon"] = random_pkmn[0]
			description_label.text = "A wild Hypno appears! It seems to have your %s in a trance..." % random_pkmn[0].species_id.capitalize()
		_:
			description_label.text = event_data.get("description", "")
		
	
	if event_data.get("dynamic_choices", false):
		_generate_dynamic_choices()
	else:
		_generate_static_choices(event_data.get("choices", []))
	

func _on_choice_selected(effects: Dictionary) -> void:
	EventEffectResolver.apply(effects, char_stats, run_stats)
	SFXPlayer.play(PC_MENU_SELECT)
	Events.event_room_exited.emit()
	queue_free()


func _generate_static_choices(choices) -> void:
	for choice in choices:
		var btn := Button.new()
		btn.text = choice["text"]
		btn.pressed.connect(func(): _on_choice_selected(choice["effects"]))
		choices_container.add_child(btn)


func _generate_dynamic_choices() -> void:
	match event_data.get("special_type", ""):
		"move_tutor":
			_generate_move_tutor_choices()
		"tm":
			_generate_tm_choices()
		"hypno_trance":
			_generate_hypno_trance_choices()
		_:
			_generate_type_based_choices()

func _generate_move_tutor_choices() -> void:
	var tutor_type = event_data.get("tutor_type", "normal")
	
	for pkmn in char_stats.get_all_party_members():
		var type := pkmn.type[0]
		var btn := Button.new()
		btn.text = "Teach %s a rare %s-type move" % [pkmn.species_id.capitalize(), tutor_type.capitalize()]

		var effects := {
			"gain_rare_card_of_type_for_pokemon": {
				"type": tutor_type,
				"uid": pkmn.uid
			}
		}
		btn.pressed.connect(func(): _on_choice_selected(effects))
		choices_container.add_child(btn)

	generate_skip_button("Decline the tutor's offer")


func _generate_tm_choices() -> void:
	var tm_id = event_data.get("tm_id", "tackle")

	for pkmn in char_stats.get_all_party_members():
		var btn := Button.new()
		btn.text = "Teach %s TM (%s)" % [pkmn.species_id.capitalize(), tm_id.capitalize()]

		var effects := {
			"teach_tm": {
				"move_id": tm_id,
				"uid": pkmn.uid
			}
		}
		btn.pressed.connect(func(): _on_choice_selected(effects))
		choices_container.add_child(btn)

	generate_skip_button("Leave the TM")


func _generate_hypno_trance_choices() -> void:
	var pkmn = event_data["target_pokemon"]
	var uid = pkmn.uid
	var matching_cards = char_stats.get_party_pkmn_cards(uid)
	
	# Option 1: Forget
	var btn1 := Button.new()
	btn1.text = "FORGET a move.."
	btn1.pressed.connect(func():
		var pile := CardPile.new()
		pile.cards = matching_cards.cards
		var view = card_pile_view
		view.card_pile = pile
		view.char_stats = char_stats
		view.show_current_view("Choose....")
		view.card_detail_overlay.button.text = "Forget"
		view.card_detail_overlay.button.visible = true
		view.card_detail_overlay.button.pressed.connect(func():
			var selected = view.card_detail_overlay.tooltip_card.get_child(0).card
			char_stats.deck.remove_card(selected)
			view.queue_free()
			Events.event_room_exited.emit()
			queue_free()
		)
		add_child(view)
	)
	choices_container.add_child(btn1)

	# Option 2: Transform
	var btn2 := Button.new()
	btn2.text = "TRANSFORM a move.."
	btn2.pressed.connect(func():
		var pile := CardPile.new()
		pile.cards = matching_cards.cards
		var view := card_pile_view
		view.card_pile = pile
		view.char_stats = char_stats
		view.show_current_view("Choose....")
		view.card_detail_overlay.button.text = "Transform"
		view.card_detail_overlay.button.visible = true
		view.card_detail_overlay.button.pressed.connect(func():
			var selected = view.card_detail_overlay.tooltip_card.get_child(0).card
			char_stats.deck.remove_card(selected)
			var all_ids = MoveData.moves.keys()
			all_ids.shuffle()
			var new_card = Utils.create_card(all_ids[0])
			new_card.pkmn_owner_uid = pkmn.uid
			new_card.pkmn_owner_name = pkmn.species_id
			new_card.pkmn_icon = pkmn.icon
			char_stats.deck.add_card(new_card)
			view.queue_free()
			Events.event_room_exited.emit()
			queue_free()
		)
		add_child(view)
	)
	choices_container.add_child(btn2)

	# Option 3: Flee
	generate_skip_button("Flee from Hypno")




func _generate_type_based_choices() -> void:
	var stone_type = event_data.get("stone_type", "normal")
	
	for pkmn in char_stats.get_all_party_members():
		var btn := Button.new()
		btn.text = "Let %s touch the stone..." % pkmn.species_id.capitalize()

		var effects := {
			"gain_random_card_of_type_for_pokemon": {
				"type": stone_type,
				"uid": pkmn.uid
			}
		}
		btn.pressed.connect(func(): _on_choice_selected(effects))
		choices_container.add_child(btn)

	generate_skip_button("Leave the stone untouched")



func generate_skip_button(skip_text: String) -> void:
	var skip_btn := Button.new()
	skip_btn.text = skip_text
	skip_btn.pressed.connect(func(): _on_choice_selected({}))
	choices_container.add_child(skip_btn)


func _pick_random_type() -> String:
	var types := MoveData.type_to_moves.keys()
	types.shuffle()
	return types[0]

func _pick_random_tm() -> String:
	var candidates := []
	for move_id in MoveData.moves.keys():
		var move = MoveData.moves[move_id]
		if move and move.get("rarity", "") in ["uncommon", "rare"]:
			candidates.append(move_id)

	if candidates.is_empty():
		return "tackle"

	candidates.shuffle()
	return candidates[0]
