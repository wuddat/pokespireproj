extends Node

static func print_resource(resource: Resource) -> void:
	if resource == null:
		print("Resource is null.")
		return

	print("----- Resource Properties -----")
	for prop in resource.get_property_list():
		var name = prop.name
		var value = resource.get(name)
		print("%s: %s" % [name, value])
	print("------------------------------")

func to_typed_string_array(input: Array) -> Array[String]:
	var result: Array[String] = []
	for item in input:
		result.append(str(item))
	return result


static func print_node(node: Node) -> void:
	if node == null:
		print("Node is null.")
		return
	
	print("===== Node Debug Info (%s) =====" % node.name)

	# Print exported and internal properties
	var property_list := node.get_property_list()
	for prop in property_list:
		var name = prop.name
		var value = node.get(name)
		print("%s: %s" % [name, value])


static func get_evolution_options(pkmn: PokemonStats) -> Array[Card]:
	var options: Array[Card] = []

	# Filter rare/uncommon moves
	var rare_ids := pkmn.move_ids.filter(func(id: String) -> bool:
		var data = MoveData.moves.get(id)
		return data and data.get("rarity", "common") in ["rare", "uncommon"]
	)

	if rare_ids.is_empty():
		rare_ids = pkmn.move_ids

	for id in rare_ids:
		var move_data = MoveData.moves.get(id)
		if move_data == null:
			continue

		var category = move_data.get("category", "attack")
		var card_type = null

		match category:
			"attack":
				card_type = preload("res://data/moves/attack.tres")
			"defense":
				card_type = preload("res://data/moves/block.tres")
			"power":
				card_type = preload("res://data/moves/power.tres")
			"shift":
				card_type = preload("res://data/moves/shift.tres")
			_:
				card_type = null

		if card_type:
			var card = card_type.duplicate()
			card.setup_from_data(move_data)
			card.pkmn_owner_uid = pkmn.uid
			card.pkmn_owner_name = pkmn.species_id
			card.pkmn_icon = pkmn.icon
			options.append(card)

	return options.slice(0, 3)
