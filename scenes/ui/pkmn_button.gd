class_name PkmnButton
extends TextureButton

@export var pkmn: PokemonStats : set = set_pkmn

@onready var name_label: Label = $Label

func set_pkmn(new_pkmn: PokemonStats) -> void:
	pkmn = new_pkmn

	# Set the sprite (the button's texture)
	texture_normal = pkmn.art

	# Set the label text to species name
	name_label.text = pkmn.species_id.capitalize()
