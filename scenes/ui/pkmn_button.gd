class_name PkmnButton
extends TextureButton  

@export var pkmn: PokemonStats : set = set_pkmn
@onready var name_label: Label = $Label

func set_pkmn(new_pkmn: PokemonStats) -> void:
	pkmn = new_pkmn
	texture_normal = pkmn.art
	name_label.text = pkmn.species_id.capitalize()
