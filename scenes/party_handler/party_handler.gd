class_name PartyHandler
extends Node
#152,192 location - test 284, 124
@export var POS_0 := Vector2(152,192)
@export var POS_1 := Vector2(200, 210)
@export var POS_2 := Vector2(95, 210)


@export var max_party_size := 6
@export var character_stats: CharacterStats

var PKMN_BATTLE_UNIT := preload("res://scenes/battle/pokemon_battle_unit.tscn")

var active_battle_party: Array[PokemonStats] = []
var active_indexes := [0,1,2]


func _ready():
	if not Events.player_pokemon_switch_requested.is_connected(_on_party_pokemon_switch_requested):
		Events.player_pokemon_switch_requested.connect(_on_party_pokemon_switch_requested)



func initialize_party_for_battle() -> void:
	if character_stats == null:
		push_error("PartyHandler requires a reference to character_stats")
		return
	
	spawn_active_pokemon()


func add_to_battle_party(pokemon: PokemonStats) -> bool:
	if active_battle_party.size() >= max_party_size:
		return false
	active_battle_party.append(pokemon)
	return true

func get_active_pokemon() -> Array[PokemonStats]:
	var actives: Array[PokemonStats] = []
	for pkmn in active_battle_party:
		print("requested pkmn: %s" % pkmn.species_id)
		print("pkmn HP: %s" % pkmn.health)
		if pkmn.health > 0:
			actives.append(pkmn)
		if actives.size() == 3:
			break
	return actives


func spawn_active_pokemon():
	var actives := get_active_pokemon()
	for i in range(actives.size()):
		var pokemon := actives[i]
		var unit := PKMN_BATTLE_UNIT.instantiate() as PokemonBattleUnit
		unit.stats = pokemon
		unit.spawn_position = "POS_%s" % i
			
		if not unit.stats.stats_changed.is_connected(sync_battle_health_to_party_data):
			unit.stats.stats_changed.connect(sync_battle_health_to_party_data)
			
		match i:
			0: unit.position = POS_0
			1: unit.position = POS_1
			2: unit.position = POS_2
			_: unit.position = Vector2(0, 0)
		add_child(unit)
		#DEBUG.print_resource(pokemon)
		print("Spawned Pokémon: %s with HP %d" % [pokemon.species_id, pokemon.health])


func get_active_pokemon_nodes() -> Array[PokemonBattleUnit]:
	var typed_array: Array[PokemonBattleUnit] = []
	for node in get_children():
		if node is PokemonBattleUnit:
			typed_array.append(node as PokemonBattleUnit)
	return typed_array

func sync_battle_health_to_party_data() -> void:
	if character_stats == null:
		return

	# Just update matching Pokémon in the full party
	for pkmn in active_battle_party:
		for i in range(character_stats.current_party.size()):
			if character_stats.current_party[i].uid == pkmn.uid:
				character_stats.current_party[i] = pkmn



func finalize_battle_party(pkmn_list: Array[PokemonStats]) -> void:
	active_battle_party.clear()
	print("Finalizing Battle Party:")
	for pkmn in pkmn_list:
		print("- %s | UID: %s | HP: %d" % [pkmn.species_id, pkmn.uid, pkmn.health])
		if add_to_battle_party(pkmn):
			continue
		else:
			push_warning("Party is full. Could not add: %s" % pkmn.species_id)



func _on_party_pokemon_switch_requested(uid_out: String, uid_in: String) -> void:
	print("Switch Requested: OUT = %s | IN = %s" % [uid_out, uid_in])
	for child in get_children():
		if child is PokemonBattleUnit:
			print("Existing Unit: %s | UID: %s" % [child.stats.species_id, child.stats.uid])
			
	for child in get_children():
		if child is PokemonBattleUnit and child.stats.uid == uid_out:
			print("Switching OUT: %s" % child.stats.species_id)
			print("active_battle_party before: ")
			for p in active_battle_party:
				print(p.species_id)
				if p.uid == uid_out:
					active_battle_party.erase(p)
			print("active_battle_party after: ")
			for p in active_battle_party:
				print(p.species_id)
			var old_unit := child as PokemonBattleUnit
			var slot := old_unit.spawn_position
			sync_battle_health_to_party_data()
			old_unit.queue_free()

			# pkmn to swap in
			for pkmn in character_stats.current_party:
				print("Check Battle Party: %s | UID: %s" % [pkmn.species_id, pkmn.uid])
				if pkmn.uid == uid_in:
					print("Switching IN: %s" % pkmn.species_id)
					var new_unit := PKMN_BATTLE_UNIT.instantiate()
					new_unit.stats = pkmn
					new_unit.spawn_position = slot
			
					if not new_unit.stats.stats_changed.is_connected(sync_battle_health_to_party_data):
						new_unit.stats.stats_changed.connect(sync_battle_health_to_party_data)
						
					match slot:
						"POS_0": new_unit.position = POS_0
						"POS_1": new_unit.position = POS_1
						"POS_2": new_unit.position = POS_2
						_: new_unit.position = Vector2(0, 0)
					add_child(new_unit)
					active_battle_party.append(new_unit.stats as PokemonStats)
					for p in active_battle_party:
						print(p.species_id)
					Events.player_pokemon_switch_completed.emit(pkmn)
					return
