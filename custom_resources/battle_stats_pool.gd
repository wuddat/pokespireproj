class_name BattleStatsPool
extends Resource

@export var pool: Array[BattleStats]

var total_weights_by_tier := [0.0, 0.0, 0.0]

#TODO deprecate this for battles _get_all_battles_for_tier_and_type
func _get_all_battles_for_tier(tier: int) -> Array[BattleStats]:
	return pool.filter(
		func(battle: BattleStats):
			return battle.battle_tier == tier
	)


func _get_all_battles_for_tier_and_type(tier: int, type: String) -> Array[BattleStats]:
	return pool.filter(
		func(battle: BattleStats):
			return battle.battle_tier == tier and battle.encounter_type == type
	)


func get_random_battle_for_tier_and_type(tier: int, type: String) -> BattleStats:
	var filtered := _get_all_battles_for_tier_and_type(tier, type)
	if filtered.is_empty():
		push_warning("No battles found for tier %d and type %s" % [tier, type])
		return null
	
	var selected_battle = RNG.array_pick_random(filtered).duplicate()
	selected_battle.assign_enemy_pkmn_party()

	if selected_battle.encounter_type == "Trainer":
		# Randomly assign a trainer type
		var trainer_types := ["Aroma Lady","Battle Girl","Biker", "Bird Keeper","Black Belt","Bug Catcher","Engineer", "Fisher", "Hiker", "Psychic","Youngster",]
		#var trainer_types := ["Fisher"]
		selected_battle.trainer_type = RNG.array_pick_random(trainer_types)
		selected_battle.assign_enemy_pkmn_party()

	return selected_battle


func get_wild_battle_for_tier(tier: int) -> BattleStats:
	return get_random_battle_for_tier_and_type(tier, "Wild")


func get_trainer_battle_for_tier(tier: int) -> BattleStats:
	return get_random_battle_for_tier_and_type(tier, "Trainer")


func get_legendary_battle_for_tier(tier: int) -> BattleStats:
	return get_random_battle_for_tier_and_type(tier, "Legendary")


func get_boss_battle_for_tier(tier: int) -> BattleStats:
	return get_random_battle_for_tier_and_type(tier, "Boss")


func _setup_weight_for_tier(tier: int) -> void:
	var battles := _get_all_battles_for_tier(tier)
	total_weights_by_tier[tier] = 0.0
		
	for battle: BattleStats in battles:
		total_weights_by_tier[tier] += battle.weight
		battle.accumulated_weight = total_weights_by_tier[tier]


func get_random_battle_for_tier(tier: int) -> BattleStats:
	var roll := RNG.instance.randf_range(0.0, total_weights_by_tier[tier])
	var battles := _get_all_battles_for_tier(tier)
	
	for battle: BattleStats in battles:
		if battle.accumulated_weight > roll:
			return battle
		
	return null


func setup() -> void:
	for i in 3:
		_setup_weight_for_tier(i)
