#save_data.gd
class_name SaveData
extends Resource

const SAVE_PATH = "user://savegame.tres"

#Playerstats
@export var run_stats: RunStats
@export var char_stats: CharacterStats
@export var current_deck: CardPile
@export var current_party: Array[PokemonStats]
@export var draftable_cards: CardPile
@export var item_inventory: ItemInventory

#Mapstats
@export var map_data: Array[Array]
@export var last_room: Room
@export var floors_climbed: int
@export var was_on_map: bool

#RNGstats
@export var rng_seed: int
@export var rng_state: int


func save_data() -> void:
	var err := ResourceSaver.save(self, SAVE_PATH)
	assert(err == OK, "Couldn't save the game!")
	print("Game saved")


static func load_data() -> SaveData:
	if FileAccess.file_exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH) as SaveData
	return null


static func delete_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
