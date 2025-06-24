class_name BattleStats
extends Resource

@export_enum("Wild", "Trainer", "Legendary", "Boss") var encounter_type := "Wild"
@export_enum("Youngster", "Hiker", "Fisher",) var trainer_type:= "Youngster"

@export_range(0,2) var battle_tier: int
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var enemies: PackedScene #TODO this may need to be changed for enemy distribution

@export_category("Enemy Types")
@export_enum("Normal", "Water", "Rock", "Any") var pokemon_type:= "Normal"
@export var enemy_pkmn_party: Array[String] = []

var trainer_sprite: Texture

var is_trainer_battle: bool:
	get:
		return encounter_type == "Trainer"

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
					"Youngster":
						trainer_sprite = preload("res://art/trainer/youngster.png")
						match battle_tier:
							0:
								enemy_pkmn_party = ["rattata", "rattata", "pidgey", "raticate"]
							1:
								enemy_pkmn_party = ["raticate", "raticate", "pidgeotto", "ghastly"]
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
