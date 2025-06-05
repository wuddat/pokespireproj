class_name PartyHandler
extends Node
#152,192 location - test 284, 124
@export var POS_1 := Vector2(152,192)
@export var POS_2 := Vector2(200, 210)
@export var POS_3 := Vector2(95, 210)

@export var max_party_size := 6
var party: Array[PokemonStats] = []
var active_indexes := [0,1,2]

func _ready() -> void:
	var mankey := Pokedex.create_pokemon_instance("mankey")
	var bulbasaur := Pokedex.create_pokemon_instance("bulbasaur")
	var weedle := Pokedex.create_pokemon_instance("weedle")
	add_to_party(bulbasaur)
	add_to_party(mankey)
	add_to_party(weedle)
	


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
