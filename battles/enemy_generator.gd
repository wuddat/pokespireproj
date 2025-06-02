extends Node2D
#
#func _ready() -> void:
	#await get_tree().process_frame  # ensure all children are initialized
	#
	#var species_ids = Pokedex.pokedex.keys()
	#print("tier loaded")
	#for child in get_children():
		#print("Child loaded")
		#if child is Enemy:
			#print("Child IS enemy")
			#var new_stats = preload("res://enemies/generic_enemy/generic_enemy.tres").duplicate()
			#var random_id = species_ids.pick_random()
			#new_stats.species_id = random_id
			#print("random id selected: ", random_id)
			#child.stats = new_stats
		#print("Child enemies NOT FOUND")
		#
