class_name PartyHandler
extends Node
#152,192 location - test 284, 124
@export var POS_1 := Vector2(152,192)
@export var POS_2 := Vector2(200, 210)
@export var POS_3 := Vector2(95, 210)


@export var max_party_size := 6
@export var character_stats: CharacterStats

var active_party: Array[PokemonStats] = []
var active_indexes := [0,1,2]


func initialize_party_for_battle() -> void:
	if character_stats == null:
		push_error("PartyHandler requires a reference to character_stats")
		return
	
	spawn_active_pokemon()


func add_to_party(pokemon: PokemonStats) -> bool:
	if active_party.size() >= max_party_size:
		return false
	active_party.append(pokemon)
	return true

func get_active_pokemon() -> Array[PokemonStats]:
	var actives: Array[PokemonStats] = []
	for pkmn in active_party:
		if pkmn.health > 0:
			actives.append(pkmn)
		if actives.size() == 3:
			break
	return actives


func spawn_active_pokemon():
	var actives := get_active_pokemon()
	for i in range(actives.size()):
		var pokemon := actives[i]
		var unit := preload("res://scenes/battle/pokemon_battle_unit.tscn").instantiate() as PokemonBattleUnit
		unit.stats = pokemon
			
		if not unit.stats.stats_changed.is_connected(update_party_health_in_character_stats):
			unit.stats.stats_changed.connect(update_party_health_in_character_stats)
		unit.stats.stats_changed.connect(update_party_health_in_character_stats)
			
		match i:
			0: unit.position = POS_1
			1: unit.position = POS_2
			2: unit.position = POS_3
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

func update_party_health_in_character_stats() -> void:
	if character_stats == null:
		return
	character_stats.current_party = active_party.duplicate()


func set_active_party(pkmn_list: Array[PokemonStats]) -> void:
	active_party.clear()
	for pkmn in pkmn_list:
		if add_to_party(pkmn):
			continue
		else:
			push_warning("Party is full. Could not add: %s" % pkmn.species_id)
