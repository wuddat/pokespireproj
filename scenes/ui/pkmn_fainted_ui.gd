class_name PkmnFaintedUI
extends Control

@onready var party_pokemon: HBoxContainer = %PartyPokemon

var pkmn_btn = preload("res://scenes/ui/pkmn_button.tscn")
var char_stats: CharacterStats
var active_battlers: Array[PokemonStats]
var faint_to_switch_out: String

func _ready() -> void:
	if not Events.party_pokemon_fainted.is_connected(_show_fainted_screen):
		Events.party_pokemon_fainted.connect(_show_fainted_screen)
		

func _show_fainted_screen(fainted_pkmn: PokemonBattleUnit) -> void:
	faint_to_switch_out = fainted_pkmn.stats.uid
	party_pokemon.get_children().map(func(c): c.queue_free())

	if not char_stats:
		push_warning("char_stats unassigned on PkmnFaintedUI!")
		return
	
	var active_uids := []
	for battler in get_tree().get_first_node_in_group("party_handler").get_active_pokemon():
		if battler.uid != faint_to_switch_out:
			active_uids.append(battler.uid)


	var switchable_found := false
	for pkmn in char_stats.current_party:
		if pkmn.health > 0 and pkmn.uid != faint_to_switch_out and not active_uids.has(pkmn.uid):
			switchable_found = true
			var btn = pkmn_btn.instantiate()
			btn.get_node("Label").text = pkmn.species_id.capitalize()
			btn.texture_normal = pkmn.icon
			btn.connect("pressed", Callable(self, "_on_slot_pressed").bind(pkmn.uid))
			party_pokemon.add_child(btn)

	# 👇 Only show UI if there are valid switch options
	if switchable_found:
		show()
	else:
		print("No valid Pokémon to switch into — skipping faint UI.")

			

func _on_slot_pressed(uid: String) -> void:
	print("faint_to_switch_out UID is: ", faint_to_switch_out)
	Events.player_pokemon_switch_requested.emit(faint_to_switch_out, uid)
	hide()
