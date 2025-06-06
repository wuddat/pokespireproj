extends Control

var char_stats: CharacterStats


@onready var party_buttons: HBoxContainer = $"."
@onready var slot_1: TextureButton = %Slot1
@onready var slot_2: TextureButton = %Slot2
@onready var slot_3: TextureButton = %Slot3
@onready var slot_4: TextureButton = %Slot4
@onready var slot_5: TextureButton = %Slot5
@onready var slot_6: TextureButton = %Slot6

var active_pokemon: Array[PokemonStats] = []
var selected_indexes := [0]

func _ready() -> void:
	for i in range(6):
		var button = $".".get_child(i)
		button.pressed.connect(_on_slot_pressed.bind(i))
		
	if char_stats == null:
		return
		
	for i in range(char_stats.current_party.size()):
		var pkmn = char_stats.current_party[i]
		if i <= 3:
				active_pokemon.append(pkmn)
	
	populate_buttons()


func populate_buttons() -> void:
	for i in range(6):
		var button = $".".get_child(i) as TextureButton
		if i < char_stats.current_party.size():
			var pkmn = char_stats.current_party[i]
			button.texture_normal = pkmn.icon if pkmn.health >= 0 else preload("res://art/dottedline.png")
			button.disabled = pkmn.health <= 0
			button.modulate = Color.WHITE if i in selected_indexes else Color.DIM_GRAY
		else:
			button.texture_normal = preload("res://art/dottedline.png")


func _on_slot_pressed(index: int) -> void:
	if index in selected_indexes:
		if selected_indexes.size() > 1:
			selected_indexes.erase(index)
	else:
		if selected_indexes.size() < 3:
			selected_indexes.append(index)
	populate_buttons()


func get_selected_pokemon() -> Array[PokemonStats]:
	var selected := []
	for i in selected_indexes:
		selected.append(char_stats.current_party[i])
	return selected
