#card.gd
class_name Card
extends Resource

enum Type {ATTACK, SKILL, POWER, SHIFT, STATUS}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, SINGLE_ALLY, ALL_ENEMIES, ALL_ALLIES, ALL, RANDOM_ENEMY, SPLASH}
enum PkmnType {NORMAL, GRASS, FIRE, WATER, FIGHTING, ELECTRIC, FLYING, BUG, POISON, ICE, ROCK, GROUND, STEEL, PSYCHIC, GHOST, DARK, FAIRY, DRAGON}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
}

const TYPE_COLORS := {
	Card.Type.ATTACK: Color.WHITE_SMOKE,
	Card.Type.SKILL: Color.WHITE_SMOKE,
	Card.Type.POWER: Color.WHITE_SMOKE,
	Card.Type.SHIFT: Color.WHITE_SMOKE,
	Card.Type.STATUS: Color.WHITE_SMOKE
}

const PKMN_COLORS := {
	Card.PkmnType.NORMAL: Color(.659,.655,.478),
	Card.PkmnType.GRASS: Color(.478,.78,.298),
	Card.PkmnType.FIRE: Color(.933,.506,.188),
	Card.PkmnType.WATER: Color(.388,.565,.941),
	Card.PkmnType.FIGHTING: Color(.761,.18,.157),
	Card.PkmnType.ELECTRIC: Color(.969,.816,.173),
	Card.PkmnType.FLYING: Color(.663,.561,.953),
	Card.PkmnType.BUG: Color(.651,.725,.102),
	Card.PkmnType.POISON: Color(.639,.243,.631),
	Card.PkmnType.ICE: Color(.588,.851,.839),
	Card.PkmnType.ROCK: Color(.714,.631,.212),
	Card.PkmnType.GROUND: Color(.886,.749,.396),
	Card.PkmnType.STEEL: Color(.718,.718,.808),
	Card.PkmnType.PSYCHIC: Color(.976,.333,.529),
	Card.PkmnType.GHOST: Color(.451,.341,.592),
	Card.PkmnType.DARK: Color(.439,.341,.275),
	Card.PkmnType.FAIRY: Color(.839,.522,.678),
	Card.PkmnType.DRAGON: Color(.435,.208,.988),
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
@export var base_power: int


@export_group("Card Visuals")
@export var icon: Texture
@export var pkmn_icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

@export_group("Card Effects")
@export var status_effects: Array[Status]
@export var effect_chance: float = 1
@export var dmg_block: int = 0
@export var multiplay: int = 1
@export var randomplay: int = 0
@export var requires_status: String = ""
@export var bonus_damage_if_target_has_status: String = ""
@export var bonus_damage_multiplier: float = 1.0
@export var splash_damage: int = 0
@export var shift_enabled: int = 0
@export var lead_effects: Dictionary = {}
@export var card_draw: int = 0

@export_group("Self Effects")
@export var self_heal: int
@export var self_damage: int = 0
@export var self_damage_percent_hp: float = 0
@export var self_status: Array[Status] = []
@export var self_block: int = 0
@export var self_shift: int = 0

var random_targets = []
@export var current_cost: int
@export var base_card: Card = null
@export var lead_enabled: bool = false


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
				var selected = enemy_group[RNG.instance.randi() % enemy_group.size()]
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
	current_cost = cost
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
	card_draw = data.get("card_draw", 0)

	

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
		var soundpath = data["sound_path"]
		sound = load(soundpath)
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
	
	if data.has("lead_effects"):
		lead_effects = data["lead_effects"]
	

func emit_dialogue(texts: Array[String]) -> void:
	for text in texts:
		Events.battle_text_requested.emit(text)
		print(text)


func get_pkmn_color() -> Color:
	var type_str := damage_type.to_upper()
	match type_str:
		"NORMAL": return PKMN_COLORS[PkmnType.NORMAL]
		"GRASS": return PKMN_COLORS[PkmnType.GRASS]
		"FIRE": return PKMN_COLORS[PkmnType.FIRE]
		"WATER": return PKMN_COLORS[PkmnType.WATER]
		"FIGHTING": return PKMN_COLORS[PkmnType.FIGHTING]
		"ELECTRIC": return PKMN_COLORS[PkmnType.ELECTRIC]
		"FLYING": return PKMN_COLORS[PkmnType.FLYING]
		"BUG": return PKMN_COLORS[PkmnType.BUG]
		"POISON": return PKMN_COLORS[PkmnType.POISON]
		"ICE": return PKMN_COLORS[PkmnType.ICE]
		"ROCK": return PKMN_COLORS[PkmnType.ROCK]
		"GROUND": return PKMN_COLORS[PkmnType.GROUND]
		"STEEL": return PKMN_COLORS[PkmnType.STEEL]
		"PSYCHIC": return PKMN_COLORS[PkmnType.PSYCHIC]
		"GHOST": return PKMN_COLORS[PkmnType.GHOST]
		"DARK": return PKMN_COLORS[PkmnType.DARK]
		"FAIRY": return PKMN_COLORS[PkmnType.FAIRY]
		"DRAGON": return PKMN_COLORS[PkmnType.DRAGON]
		_:
			return Color.WHITE

func apply_lead_mods(card: Card) -> void:
	lead_enabled = true
	if card.lead_effects.has("power"):
		card.power = card.lead_effects["power"]
		card.base_power = card.power
	
	if card.lead_effects.has("self_damage"):
		card.self_damage = card.lead_effects["self_damage"]
		
	if card.lead_effects.has("description"):
		card.tooltip_text = card.lead_effects["description"]
		
	if card.lead_effects.has("multiplay"):
		card.multiplay = card.lead_effects["multiplay"]
		
	if card.lead_effects.has("status_effects"):
		var raw_ids = card.lead_effects["status_effects"]
		var typed_ids = Utils.to_typed_string_array(raw_ids)
		
		status_effects.clear()
		status_effects.append_array(StatusData.get_status_effects_from_ids(typed_ids))
		
	if card.lead_effects.has("self_status"):
		var raw_ids = lead_effects["self_status"]
		var typed_ids = Utils.to_typed_string_array(raw_ids)
		self_status.clear()
		self_status.append_array(StatusData.get_status_effects_from_ids(typed_ids))


func reset_to_base_card() -> void:
	if base_card == null:
		push_warning("⚠️ Tried to reset card without a base_card.")
		return
		
	lead_enabled = false
	# --- Card Attributes ---
	id = base_card.id
	name = base_card.name
	type = base_card.type
	rarity = base_card.rarity
	cost = base_card.cost
	current_cost = base_card.current_cost
	power = base_card.power
	base_power = base_card.base_power
	target_damage_percent_hp = base_card.target_damage_percent_hp
	damage_type = base_card.damage_type
	exhausts = base_card.exhausts
	pkmn_owner_uid = base_card.pkmn_owner_uid
	pkmn_owner_name = base_card.pkmn_owner_name

	# --- Card Visuals ---
	icon = base_card.icon
	pkmn_icon = base_card.pkmn_icon
	tooltip_text = base_card.tooltip_text
	sound = base_card.sound

	# --- Card Effects ---
	status_effects = base_card.status_effects.duplicate()
	effect_chance = base_card.effect_chance
	dmg_block = base_card.dmg_block
	multiplay = base_card.multiplay
	randomplay = base_card.randomplay
	requires_status = base_card.requires_status
	bonus_damage_if_target_has_status = base_card.bonus_damage_if_target_has_status
	bonus_damage_multiplier = base_card.bonus_damage_multiplier
	splash_damage = base_card.splash_damage
	shift_enabled = base_card.shift_enabled
	lead_effects = base_card.lead_effects.duplicate()
	card_draw = base_card.card_draw

	# --- Self Effects ---
	self_heal = base_card.self_heal
	self_damage = base_card.self_damage
	self_damage_percent_hp = base_card.self_damage_percent_hp
	self_status = base_card.self_status.duplicate()
	self_block = base_card.self_block
	self_shift = base_card.self_shift

 
