#rng.gd
extends Node

var instance: RandomNumberGenerator

func _ready() -> void:
	initialize()


func initialize() -> void:
	instance = RandomNumberGenerator.new()
	instance.randomize()


func set_from_save_data(seed_number: int, state: int) -> void:
	instance = RandomNumberGenerator.new()
	instance.seed = seed_number
	instance.state = state


func array_pick_random(array: Array) -> Variant:
	return array[instance.randi() % array.size()]


func array_shuffle(array: Array) -> void:
	if array.size() < 2:
		return
	
	for i in range(array.size()-1, 0, -1):
		var j := instance.randi() % (i+1)
		var tmp = array[j]
		array[j] = array[i]
		array[i] = tmp
