class_name PartySelector
extends Control

var char_stats: CharacterStats


@onready var party_buttons: HBoxContainer = $"."
@onready var slot_1: TextureButton = %Slot1
@onready var slot_2: TextureButton = %Slot2
@onready var slot_3: TextureButton = %Slot3
@onready var slot_4: TextureButton = %Slot4
@onready var slot_5: TextureButton = %Slot5
@onready var slot_6: TextureButton = %Slot6

var currently_battling_pokemon: Array[PokemonStats] = []
var highlighted_in_bar_pkmn: Array[String] = []

var in_battle := false
var switching := false
var selected_switch_out_uid:= ""


func _ready() -> void:
	await get_tree().process_frame
	for i in range(6):
		var button = $".".get_child(i)
		button.pressed.connect(_on_slot_pressed.bind(i))
		
	if char_stats == null:
		return
		
	for i in range(min(3, char_stats.current_party.size())):
		var pkmn = char_stats.current_party[i]
		highlighted_in_bar_pkmn.append(pkmn.uid)
	sync_highlight_to_battling_pokemon()
	if not Events.player_pokemon_switch_completed.is_connected(_on_pokemon_switch):
		Events.player_pokemon_switch_completed.connect(_on_pokemon_switch)
	if not Events.party_pokemon_fainted.is_connected(_on_party_pokemon_fainted):
		Events.party_pokemon_fainted.connect(_on_party_pokemon_fainted)
	if not Events.added_pkmn_to_party.is_connected(_on_party_pokemon_added):
		Events.added_pkmn_to_party.connect(_on_party_pokemon_added)
	if not Events.evolution_completed.is_connected(update_buttons):
		Events.evolution_completed.connect(update_buttons)
	update_buttons()


func update_buttons() -> void:
	for pkmn in char_stats.current_party:
		if pkmn.health <= 0 and highlighted_in_bar_pkmn.has(pkmn.uid):
			highlighted_in_bar_pkmn.erase(pkmn.uid)
			
	for i in range(6):
		var button = $".".get_child(i) as TextureButton
		if i < char_stats.current_party.size():
			var pkmn = char_stats.current_party[i]
			
			button.texture_normal = pkmn.icon if pkmn.health >= 0 else preload("res://art/dottedline.png")
			button.disabled = pkmn.health <= 0
			
			if pkmn.health<= 0:
				button.modulate = Color.DARK_RED
			elif pkmn.uid == selected_switch_out_uid:
				button.modulate = Color.CYAN
			elif pkmn.uid in highlighted_in_bar_pkmn:
				button.modulate = Color.WHITE
			else:
				button.modulate = Color.DIM_GRAY
		else:
			button.texture_normal = preload("res://art/dottedline.png")



func _on_slot_pressed(index: int) -> void:
	if index >= char_stats.current_party.size():
		return

	var pkmn := char_stats.current_party[index]
	var uid := pkmn.uid

	print("\n=== SLOT PRESSED ===")
	print("Clicked Pokémon: %s | UID: %s | HP: %d" % [pkmn.species_id, uid, pkmn.health])
	print("In battle? %s | Switching? %s | Selected Switch Out UID: %s" % [in_battle, switching, selected_switch_out_uid])
	print("highlighted_in_bar_pkmn before click: %s" % [highlighted_in_bar_pkmn])
	print("Active Battle Pokémon UIDs:")
	for pokemon in currently_battling_pokemon:
		print("%s: %s" % [pokemon.species_id, pokemon.uid])

	if in_battle:
		if switching:
			print("Attempting switch-in with UID: %s" % uid)
			
			if uid in get_active_uids():
				print("Cancelled switch: %s is already active in battle." % uid)
				switching = false
				selected_switch_out_uid = ""
				update_buttons()
				return
			
			if uid == selected_switch_out_uid or pkmn.health <= 0:
				switching = false
				selected_switch_out_uid = ""
				update_buttons()
				print("Cancelled switching due to same UID or fainted.")
				return

			Events.player_pokemon_switch_requested.emit(selected_switch_out_uid, uid)
			for battler in currently_battling_pokemon:
				if battler.uid == selected_switch_out_uid:
					currently_battling_pokemon.erase(battler)
			for battler_uid in highlighted_in_bar_pkmn:
				if battler_uid == selected_switch_out_uid:
					highlighted_in_bar_pkmn.erase(battler_uid)
			print("Switch requested: OUT = %s, IN = %s" % [selected_switch_out_uid, uid])
			switching = false
			selected_switch_out_uid = ""
		else:
			if uid in get_active_uids():
				switching = true
				selected_switch_out_uid = uid
				print("Entering switch mode for UID: %s" % uid)
	else:
		if uid in highlighted_in_bar_pkmn:
			if highlighted_in_bar_pkmn.size() > 1:
				highlighted_in_bar_pkmn.erase(uid)
				sync_highlight_to_battling_pokemon()
				print("Deselected UID: %s" % uid)
		else:
			if highlighted_in_bar_pkmn.size() < 3:
				highlighted_in_bar_pkmn.append(uid)
				sync_highlight_to_battling_pokemon()
				print("Selected UID: %s" % uid)

	update_buttons()
	print("highlighted_in_bar_pkmn UIDs after click: %s" % [highlighted_in_bar_pkmn])
	print("=== END SLOT PRESS ===\n")

func get_active_uids() -> Array[String]:
	var uids: Array[String] = []
	for pkmn in currently_battling_pokemon:
		uids.append(pkmn.uid)
	return uids


func sync_highlight_to_battling_pokemon():
	currently_battling_pokemon.clear()
	print("Syncing highlighted Pokémon to the actively_battling_pkmn: %s" % highlighted_in_bar_pkmn)
	for pkmn in char_stats.current_party:
		if pkmn.uid in highlighted_in_bar_pkmn:
			currently_battling_pokemon.append(pkmn)
			print("- Added %s | UID: %s | HP: %d" % [pkmn.species_id, pkmn.uid, pkmn.health])
	update_buttons()



func _unhandled_input(event: InputEvent) -> void:
	if in_battle and switching and (event.is_action_pressed("ui_cancel") or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT):
		switching = false
		selected_switch_out_uid = ""
		update_buttons()



func get_selected_pokemon() -> Array[PokemonStats]:
	var selected: Array[PokemonStats] = []
	for pkmn in char_stats.current_party:
		if pkmn.uid in highlighted_in_bar_pkmn:
			selected.append(pkmn)
	print("get_selected_pokemon() returning:")
	for p in selected:
		print("- %s | UID: %s | HP: %d" % [p.species_id, p.uid, p.health])
	return selected


func _on_pokemon_switch(pkmn: PokemonStats) -> void:
	if not highlighted_in_bar_pkmn.has(pkmn.uid):
		highlighted_in_bar_pkmn.append(pkmn.uid)
	sync_highlight_to_battling_pokemon()
	update_buttons()

func _on_party_pokemon_added(pkmn: PokemonStats) -> void:
	update_buttons() 

func _on_party_pokemon_fainted(unit: PokemonBattleUnit):
	var uid = unit.stats.uid
	if highlighted_in_bar_pkmn.has(uid):
		highlighted_in_bar_pkmn.erase(uid)
	if currently_battling_pokemon.any(func(p): return p.uid == uid):
		currently_battling_pokemon = currently_battling_pokemon.filter(func(p): return p.uid != uid)
	update_buttons()
