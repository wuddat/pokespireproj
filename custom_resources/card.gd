#card.gd
class_name Card
extends Resource

enum Type {ATTACK, SKILL, POWER, SHIFT, STATUS}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, SINGLE_ALLY, ALL_ENEMIES, ALL_ALLIES, ALL, RANDOM_ENEMY, SPLASH}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
}

const TYPE_COLORS := {
	Card.Type.ATTACK: Color.RED,
	Card.Type.SKILL: Color.DARK_BLUE,
	Card.Type.POWER: Color.PURPLE,
	Card.Type.SHIFT: Color.GREEN,
	Card.Type.STATUS: Color.WEB_PURPLE
}


@export_group("Card Attributes")
@export var id: String
@export var name: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var power: int
@export var target_damage_percent_hp: float = 0.0
@export var damage_type: String
@export var exhausts: bool = false
@export var pkmn_owner_uid: String
@export var pkmn_owner_name: String
var base_power: int


@export_group("Card Visuals")
@export var icon: Texture
@export var pkmn_icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

@export_group("Card Effects")
@export var status_effects: Array[Status]
@export var effect_chance: float = 1
@export var self_heal: int
@export var self_damage: int = 0
@export var self_damage_percent_hp: float = 0
@export var self_status: Array[Status] = []
@export var self_block: int = 0
@export var dmg_block: int = 0
@export var multiplay: int = 1
@export var randomplay: int = 0
@export var requires_status: String = ""
@export var bonus_damage_if_target_has_status: String = ""
@export var bonus_damage_multiplier: float = 1.0
@export var splash_damage: int = 0
@export var shift_enabled: int = 0
@export var self_shift: int = 0


var random_targets = []


func is_single_targeted() -> bool:
	return target in [Target.SINGLE_ENEMY, Target.SINGLE_ALLY, Target.SPLASH]


func _get_targets(targets: Array[Node], battle_unit_owner: PokemonBattleUnit) -> Array[Node]:
	if not battle_unit_owner:
		return []
		
	var tree := battle_unit_owner.get_tree()
	
	var _is_player := battle_unit_owner.is_in_group("active_pokemon")
	var player_party := tree.get_nodes_in_group("active_pokemon")
	var allies_group: Array[Node] = []
	for pkmn in player_party:
		if pkmn.stats.uid != battle_unit_owner.stats.uid:
			allies_group.append(pkmn)
	var enemy_group := tree.get_nodes_in_group("enemies")
	
	match target:
		Target.SELF:
			return [battle_unit_owner]
		Target.SINGLE_ENEMY, Target.SINGLE_ALLY:
			return targets
		Target.ALL_ENEMIES:
			return enemy_group
		Target.ALL_ALLIES:
			allies_group.append(battle_unit_owner)
			return allies_group
		Target.ALL:
			return player_party + enemy_group
		Target.SPLASH:
			var splash_targets: Array[Node] = enemy_group.duplicate()
			splash_targets = splash_targets.filter(func(enemy): return enemy != targets[0])
			return targets + splash_targets
		Target.RANDOM_ENEMY:
			print("RANDOM_ENEMY group:", enemy_group)
			if enemy_group.size() > 0:
				var selected = enemy_group[randi() % enemy_group.size()]
				print("Selected random enemy:", selected.name)
				return [selected]
			return []
		_:
			return[]


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler, _battle_unit_owner: PokemonBattleUnit) -> void:
	pass


func get_default_tooltip() -> String:
	return tooltip_text


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers:ModifierHandler, _targets: Array[Node]) -> String:
		return tooltip_text



#card generation from movelist data
func setup_from_data(data: Dictionary) -> void:
	id = data.get("id", "CardIDError")
	name = data.get("name", "CardNameError")
	power = data.get("power", 88)
	base_power = power
	damage_type = data.get("type", "normal")
	target_damage_percent_hp = data.get("target_damage_percent_hp", 0.0)
	cost = data.get("cost", 88)
	tooltip_text = data.get("description", "CardToolTipError")
	var iconpath = data.get("icon_path", "res://art/arrow.png")
	icon = load(iconpath)
	multiplay = data.get("multiplay", 1)
	randomplay = data.get("randomplay", 0)
	self_damage = data.get("self_damage", 0)
	self_damage_percent_hp = data.get("self_damage_percent_hp", 0)
	self_heal = data.get("self_heal", 0)
	self_block = data.get("self_block", 0)
	dmg_block = data.get("dmg_block", 0)
	effect_chance = data.get("effect_chance", 1.0)
	splash_damage = data.get("splash_damage", 0)
	requires_status = data.get("requires_status", "")
	bonus_damage_if_target_has_status = data.get("bonus_damage_if_target_has_status", "")
	bonus_damage_multiplier = data.get("bonus_damage_multiplier", 1.0)
	shift_enabled = data.get("shift_enabled", 0)
	self_shift = data.get("self_shift", 0)

	

	match data.get("category", "attack"):
		"attack":
			type = Type.ATTACK
		"defense", "stat_mod", "status_effect":
			type = Type.SKILL
		"power":
			type = Type.POWER
		"shift":
			type = Type.SHIFT
		"status","buff","debuff":
			type = Type.STATUS

	match data.get("target", "enemy"):
		"self":
			target = Target.SELF
		"enemy", "single_enemy":
			target = Target.SINGLE_ENEMY
		"ally":
			target = Target.SINGLE_ALLY
		"allies", "all_allies":
			target = Target.ALL_ALLIES
		"all_enemies":
			target = Target.ALL_ENEMIES
		"all":
			target = Target.ALL
		"splash":
			target = Target.SPLASH
		"random_enemy":
			target = Target.RANDOM_ENEMY
		
			
	match data.get("rarity", "common"):
		"common", "Common":
			rarity = Rarity.COMMON
		"uncommon", "Uncommon":
			rarity = Rarity.UNCOMMON
		"rare", "Rare":
			rarity = Rarity.RARE
	
	if data.has("sound_path"):
		sound = load(data["sound_path"]) as AudioStream
	else:
		var soundpath = "res://art/sounds/Tackle.wav"
		sound = load(soundpath)
	
	status_effects.clear()
	if data.has("status_effects"):
		var raw_ids = data["status_effects"]
		var typed_ids = Utils.to_typed_string_array(raw_ids)
		
		status_effects.clear()
		status_effects.append_array(StatusData.get_status_effects_from_ids(typed_ids))
	
	self_status.clear()
	if data.has("self_status"):
		var raw_ids = data["self_status"]
		var typed_ids = Utils.to_typed_string_array(raw_ids)
		self_status.clear()
		self_status.append_array(StatusData.get_status_effects_from_ids(typed_ids))

func emit_dialogue(texts: Array[String]) -> void:
	for text in texts:
		Events.battle_text_requested.emit(text)
		print(text)
