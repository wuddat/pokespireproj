class_name TypeChart
extends Node


const EFFECTIVENESS := {
	"normal": {"rock": 0.5, "ghost": 0.0},
	
	"fire": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 2.0, "bug": 2.0, "rock": 0.5, "dragon": 0.5},
	
	"water": {"fire": 2.0, "water": 0.5, "grass": 0.5, "ground": 2.0, "rock": 2.0, "dragon": 0.5},
	
	"electric": {"water": 2.0, "electric": 0.5, "grass": 0.5, "ground": 0.0, "flying": 2.0, "dragon": 0.5},
	
	"grass": {"fire": 0.5, "water": 2.0, "grass": 0.5, "poison": 0.5, "ground": 2.0, "flying": 0.5, "bug": 0.5, "rock": 2.0, "dragon": 0.5},
	
	"ice": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 0.5, "ground": 2.0, "flying": 2.0, "dragon": 2.0},
	
	"fighting": {"normal": 2.0, "ice": 2.0, "rock": 2.0, "ghost": 0.0, "flying": 0.5, "poison": 0.5, "bug": 0.5, "psychic": 0.5},
	
	"poison": {"grass": 2.0, "poison": 0.5, "ground": 0.5, "rock": 0.5, "ghost": 0.5},
	
	"ground": {"fire": 2.0, "electric": 2.0, "grass": 0.5, "poison": 2.0, "flying": 0.0, "bug": 0.5, "rock": 2.0},
	
	"flying": {"electric": 0.5, "grass": 2.0, "fighting": 2.0, "bug": 2.0, "rock": 0.5},
	
	"psychic": {"fighting": 2.0, "poison": 2.0, "psychic": 0.5},
	
	"bug": {"fire": 0.5, "grass": 2.0, "fighting": 0.5, "flying": 0.5, "ghost": 0.5, "poison": 2.0, "psychic": 2.0},
	
	"rock": {"fire": 2.0, "ice": 2.0, "fighting": 0.5, "ground": 0.5, "flying": 2.0, "bug": 2.0},
	
	"ghost": {"normal": 0.0, "psychic": 0.0, "ghost": 2.0},
	
	"dragon": {"dragon": 2.0}
}

static func get_multiplier(attack_type: String, target_types: Array[String]) -> float:
	var multiplier := 1.0
	for target_type in target_types:
		if EFFECTIVENESS.has(attack_type) and EFFECTIVENESS[attack_type].has(target_type):
			multiplier *= EFFECTIVENESS[attack_type][target_type]
	return multiplier
