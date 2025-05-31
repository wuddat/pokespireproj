extends Node

var moves = {}
func _ready():
	var file = FileAccess.open("res://data/move_list.json",FileAccess.READ)
	moves = JSON.parse_string(file.get_as_text())["moves"]
