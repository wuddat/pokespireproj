class_name Card
extends Resource

enum Type {ATTACK, SKILL, POWER}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
}

const TYPE_COLORS := {
	Card.Type.ATTACK: Color.RED,
	Card.Type.SKILL: Color.DARK_BLUE,
	Card.Type.POWER: Color.PURPLE
}

const STATUS_LOOKUP := {
	"poisoned": preload("res://statuses/poisoned.tres"),
	"enraged": preload("res://statuses/enraged.tres"),
	"exposed": preload("res://statuses/exposed.tres"),
	"attack_power": preload("res://statuses/attack_power.tres"),
	"catching": preload("res://statuses/catching.tres")
}


@export_group("Card Attributes")
@export var id: String
@export var name: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var power: int
@export var exhausts: bool = false
var base_power: int


@export_group("Card Visuals")
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

@export_group("Card Effects")
@export var status_effects: Array[Status]


func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY


func _get_targets(targets: Array[Node]) -> Array[Node]:
	if not targets:
		return []
		
	var tree := targets[0].get_tree()
	
	match target:
		Target.SELF:
			return tree.get_nodes_in_group("player")
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		Target.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemies")
		_:
			return[]


func play(targets: Array[Node], char_stats: CharacterStats, modifiers: ModifierHandler) -> void:
	Events.card_played.emit(self)
	char_stats.mana -= cost
	
	if is_single_targeted():
		apply_effects(targets, modifiers)
	else:
		apply_effects(_get_targets(targets), modifiers)


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_default_tooltip() -> String:
	return tooltip_text


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers:ModifierHandler) -> String:
		return tooltip_text


#card generation from movelist data
func setup_from_data(data: Dictionary) -> void:
	id = data.get("id", "CardIDError")
	name = data.get("name", "CardNameError")
	power = data.get("power", 88)
	base_power = power
	cost = data.get("cost", 88)
	tooltip_text = data.get("description", "CardToolTipError")
	var iconpath = data.get("icon_path", "res://art/arrow.png")
	icon = load(iconpath)
	

	match data.get("category", "attack"):
		"attack":
			type = Type.ATTACK
		"defense", "stat_mod", "status_effect":
			type = Type.SKILL
		"power","buff":
			type = Type.POWER

	match data.get("target", "enemy"):
		"self":
			target = Target.SELF
		"enemy":
			target = Target.SINGLE_ENEMY
		"all_enemies":
			target = Target.ALL_ENEMIES
		"everyone":
			target = Target.EVERYONE
			
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
		for effect_id in data["status_effects"]:
			if STATUS_LOOKUP.has(effect_id):
				status_effects.append(STATUS_LOOKUP[effect_id].duplicate())
