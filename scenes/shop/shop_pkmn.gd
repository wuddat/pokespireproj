class_name ShopPkmn
extends VBoxContainer

const PKMN_UI = preload("res://scenes/ui/pkmn_button.tscn")

@export var pkmn: PokemonStats : set = set_pkmn

@onready var pkmn_container: CenterContainer = %PkmnContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var gold_cost := randi_range(100,300)


func update(run_stats: RunStats) -> void:
	if not pkmn_container or not price or not buy_button:
		return
		
	price_label.text = str(gold_cost)
	
	if run_stats.gold >= gold_cost:
		price_label.remove_theme_color_override("font_color")
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color.RED)
		buy_button.disabled = true

func set_pkmn(new_pkmn: PokemonStats) -> void:
	if not is_node_ready():
		await ready
	
	pkmn = new_pkmn
	
	for pkmn_ui in pkmn_container.get_children():
		pkmn_ui.queue_free()
	
	var new_pkmn_ui := PKMN_UI.instantiate()
	pkmn_container.add_child(new_pkmn_ui)
	new_pkmn_ui.pkmn = pkmn

func _on_buy_button_pressed() -> void:
	Events.shop_pkmn_bought.emit(pkmn, gold_cost)
	pkmn_container.queue_free()
	price.queue_free()
	buy_button.queue_free()
