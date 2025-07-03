class_name BattleStats
extends Resource




@export_enum("Wild", "Trainer", "Legendary", "Boss") var encounter_type := "Wild"
@export_enum("Aroma Lady","Battle Girl","Biker", "Bird Keeper","Black Belt","Bug Catcher","Engineer", "Fisher", "Hiker", "Psychic","Youngster",  ) var trainer_type:= "None"

@export_range(0,2) var battle_tier: int
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var enemies: PackedScene #TODO this may need to be changed for enemy distribution

@export_category("Enemy Types")
@export_enum("Normal", "Water", "Rock", "Any") var pokemon_type:= "Any"
@export var enemy_pkmn_party: Array[String] = []

var trainer_sprite: Texture
var is_trainer_battle: bool:
	get:
		return encounter_type == "Trainer"
var is_boss_battle: bool:
	get:
		return encounter_type == "Boss"
var accumulated_weight: float = 0.0


func roll_gold_reward() -> int:
	return randi_range(gold_reward_min, gold_reward_max)


func assign_enemy_pkmn_party() -> void:
	if enemy_pkmn_party == []:
		match encounter_type:
			"Wild":
				enemy_pkmn_party = Pokedex.get_species_for_tier(battle_tier)

			"Trainer":
				match trainer_type:
					"Aroma Lady":
						trainer_sprite = preload("res://art/trainer/aromalady.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["oddish", "bellsprout", "tangela", "exeggcute"]
							1:
								enemy_pkmn_party = ["tangela", "gloom", "weepinbell", "exeggutor"]
							2:
								enemy_pkmn_party = ["tangela", "exeggutor", "victreebell", "vileplume"]
					"Battle Girl":
						trainer_sprite = preload("res://art/trainer/battlegirl.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["mankey", "machop", "poliwhirl", "hitmonchan"]
							1:
								enemy_pkmn_party = ["poliwhirl", "machoke", "primeape", "hitmonchan"]
							2:
								enemy_pkmn_party = ["hitmonchan", "primeape", "poliwrath", "machamp"]
					"Biker":
						trainer_sprite = preload("res://art/trainer/biker.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["grimer", "koffing", "ekans", "koffing"]
							1:
								enemy_pkmn_party = ["muk", "arbok", "jynx", "wheezing"]
							2:
								enemy_pkmn_party = ["muk", "muk", "muk", "muk"]
					"Bird Keeper":
						trainer_sprite = preload("res://art/trainer/birdkeeper.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["pidgey", "spearow", "pidgey", "doduo"]
							1:
								enemy_pkmn_party = ["pidgeotto", "pidgeotto", "fearow", "dodrio"]
							2:
								enemy_pkmn_party = ["dodrio", "fearow", "pidgeot", "pidgeot"]
					"Black Belt":
						trainer_sprite = preload("res://art/trainer/blackbelt.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["machop", "machoke", "machoke"]
							1:
								enemy_pkmn_party = ["machoke", "machoke", "machamp", "hitmonlee"]
							2:
								enemy_pkmn_party = ["hitmonlee", "hitmonchan", "machamp", "machamp"]
					"Bug Catcher":
						trainer_sprite = preload("res://art/trainer/bugcatcher.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["caterpie", "weedle", "metapod", "kakuna"]
							1:
								enemy_pkmn_party = ["kakuna", "metapod", "butterfree", "beedrill"]
							2:
								enemy_pkmn_party = ["butterfree", "beedrill", "beedrill", "pinsir"]
					"Engineer":
						trainer_sprite = preload("res://art/trainer/engineer.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["voltorb", "magnemite", "pikachu", "elektabuzz"]
							1:
								enemy_pkmn_party = ["elektabuzz", "magneton", "jolteon", "electrode"]
							2:
								enemy_pkmn_party = ["electrode", "electrode", "electrode", "electrode"]
					"Psychic":
						trainer_sprite = preload("res://art/trainer/psychic.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["abra", "psyduck", "drowzee", "kadabra"]
							1:
								enemy_pkmn_party = ["kadabra", "hypno", "psyduck", "alakazam"]
							2:
								enemy_pkmn_party = ["raticate", "raticate", "pidgeotto"]
					"Youngster":
						trainer_sprite = preload("res://art/trainer/youngster.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["rattata", "rattata", "pidgey", "raticate"]
							1:
								enemy_pkmn_party = ["raticate", "raticate", "pidgeotto", "haunter"]
							2:
								enemy_pkmn_party = ["raticate", "raticate", "pidgeotto"]
					"Hiker":
						trainer_sprite = preload("res://art/trainer/hiker.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["geodude", "geodude", "zubat", "onix"]
							1:
								enemy_pkmn_party = ["rhyhorn", "graveler", "golbat", "golem"]
							2:
								enemy_pkmn_party = ["onix", "graveler", "golem"]

					"Fisher":
						trainer_sprite = preload("res://art/trainer/fisher.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["magikarp", "magikarp", "magikarp", "goldeen", "horsea", "dratini"]
							1:
								enemy_pkmn_party = ["magikarp", "magikarp", "seaking", "seadra", "dragonair", "gyarados"]
							2:
								enemy_pkmn_party = ["goldeen", "seaking", "gyarados"]
								
					_:
						enemy_pkmn_party = ["zubat"]

			"Boss":
				pass
