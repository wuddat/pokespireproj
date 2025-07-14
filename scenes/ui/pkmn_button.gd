class_name PkmnButton
extends TextureButton  

@export var pkmn: PokemonStats
@onready var name_label: Label = $Label

#func _ready() -> void:
	#while true:
		#await get_tree().process_frame
		#if pkmn != null:
			#set_pkmn(pkmn)
			#break

func set_pkmn(new_pkmn: PokemonStats) -> void:
	if new_pkmn == null:
		return
	pkmn = new_pkmn
	texture_normal = pkmn.art
	name_label.text = pkmn.species_id.capitalize()
