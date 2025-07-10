#pokemon_container.gd
class_name PokemonContainer
extends HBoxContainer

@export var pkmn : PokemonStats : set = _set_pkmn

@onready var button: PkmnButton = %Button
@onready var current_hp: PanelContainer = %CurrentHP
@onready var current_xp: PanelContainer = %CurrentXP
@onready var hp_text: Label = %HPText
@onready var xp_text: Label = %XPText
@onready var level: Label = %Level

#hoverables
@onready var hp_bar: PanelContainer = %HPBar
@onready var xp_bar: PanelContainer = %XPBar

var max_width_for_bars_px: float = 100.0

func _set_pkmn(value: PokemonStats) -> void:
	pkmn = value
	var health_percentage: float = pkmn.health/pkmn.max_health
	var exp_for_next_level = pkmn.get_xp_for_next_level(pkmn.level)
	var exp_percentage: float = float(pkmn.current_exp) / float(exp_for_next_level)
	
	current_hp.custom_minimum_size.x = clampi(health_percentage * max_width_for_bars_px, float(5.0), max_width_for_bars_px)
	current_hp.size.x = clampi(health_percentage * max_width_for_bars_px, float(5.0), max_width_for_bars_px)
	current_xp.custom_minimum_size.x = clampi(exp_percentage * max_width_for_bars_px, float(5.0), max_width_for_bars_px)
	current_xp.size.x = clampi(exp_percentage * max_width_for_bars_px, float(5.0), max_width_for_bars_px)
	hp_text.text = str(pkmn.health) + "/" + str(pkmn.max_health)
	xp_text.text = str(pkmn.current_exp) + "/" + str(exp_for_next_level)
	level.text = "lvl" + str(pkmn.level)
	print("exp_for_next_level: ", exp_for_next_level)
	print("exp_percentage: ", exp_percentage)
	print("pkmn.current_exp: ", pkmn.current_exp)
	print("division: ", float(pkmn.current_exp) / float(exp_for_next_level))
	print("current_hp.custom_minimum_size.x ", current_hp.custom_minimum_size.x)
	print("current_xp.custom_minimum_size.x ", current_xp.custom_minimum_size.x)
	
	
	button.texture_normal = pkmn.art
	button.name_label.text = pkmn.species_id.capitalize()
