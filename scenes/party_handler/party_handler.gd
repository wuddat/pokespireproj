class_name PartyHandler
extends Node
#152,192 location - test 284, 124
@export var POS_1 := Vector2(152,192)
@export var POS_2 := Vector2(200, 210)
@export var POS_3 := Vector2(95, 210)

@export var max_party_size := 6
@export var character_stats: CharacterStats

var party: Array[PokemonStats] = []
var active_indexes := [0,1,2]


func initialize_party_for_battle() -> void:
	if character_stats == null:
		push_error("PartyHandler requires a reference to character_stats")
		return

	for pkmn_data in character_stats.current_party:
		var instance := Pokedex.create_pokemon_instance(pkmn_data.species_id)
		instance.species_id = pkmn_data.species_id
		instance.health = pkmn_data.health
		instance.max_health = pkmn_data.max_health
		print("move ids before: ", pkmn_data.move_ids)
		instance.move_ids.append(pkmn_data.move_ids)
		print("move ids after append: ", instance.move_ids)
		add_to_party(instance)
		print("added %s to party in battle" % instance.species_id)

	spawn_active_pokemon()


func add_to_party(pokemon: PokemonStats) -> bool:
	if party.size() >= max_party_size:
		return false
	party.append(pokemon)
	return true

func get_active_pokemon() -> Array[PokemonStats]:
	var actives: Array[PokemonStats] = []
	for i in active_indexes:
		if i >= 0 and i < party.size():
			actives.append(party[i])
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
	character_stats.current_party = []
	for p in party:
		character_stats.current_party.append({
			"species_id": p.species_id,
			"max_health": p.max_health,
			"health": p.health,
			"move_ids": p.move_ids.duplicate()
		})
		print("updated %s stats" % p.species_id)
