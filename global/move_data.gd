#move_data.gd
extends Node

var moves = {}
var type_to_moves := {}
func _ready():
	var file = FileAccess.open("res://data/move_list.json",FileAccess.READ)
	moves = JSON.parse_string(file.get_as_text())["moves"]
	
	
	for move_id in moves:
		var move = moves[move_id]
		if not type_to_moves.has(move["type"]):
			type_to_moves[move["type"]] = []
		type_to_moves[move["type"]].append(move_id)
	#print(type_to_moves)
