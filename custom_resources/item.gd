#item.gd
class_name Item
extends Resource

@export_group("Item Attributes")
@export var id: String
@export var name: String
var targets: Array[Node] = []
@export var power: int
@export var target_damage_percent_hp: float = 0.0
@export var damage_type: String
@export var base_power: int
@export var description: String
@export var is_consumable: bool
@export var usable_in_battle: bool
@export var quantity: int = 1
@export var is_tm: bool = false
@export var tm_type: Card.PkmnType = Card.PkmnType.NORMAL
@export var category: String
@export var type: String

@export_group("Item Visuals")
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream

@export_group("Item Effects")
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

var random_targets = []
var current_cost: int
var base_card: Card = null
var lead_enabled: bool = false
var current_position: Vector2
