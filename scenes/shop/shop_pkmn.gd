class_name ShopPkmn
extends VBoxContainer

signal pkmn_sprite_clicked(pkmn: PokemonStats)

const PKMN_UI = preload("res://scenes/ui/pkmn_button.tscn")

@export var pkmn: PokemonStats : set = set_pkmn

@onready var pkmn_container: CenterContainer = %PkmnContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var gold_cost := RNG.instance.randi_range(100,300)
@onready var pokemon_sprite: PkmnButton = %PokemonSprite

func _ready() -> void:
	if not is_visible_in_tree():
		await ready
	else:
		print("❌ ERROR: pokemon_sprite has no 'pressed' signal")
	pokemon_sprite.pressed.connect(_on_sprite_pressed)

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
	print("👀 Setting pkmn:", pkmn.species_id)

	for pkmn_ui in pkmn_container.get_children():
		pkmn_ui.queue_free()
	
	var new_pkmn_ui := PKMN_UI.instantiate()
	pkmn_container.add_child(new_pkmn_ui)
	new_pkmn_ui.set_pkmn(pkmn)
	new_pkmn_ui.pkmn = pkmn

	# Connect only once
	if not new_pkmn_ui.is_connected("pressed", Callable(self, "_on_sprite_pressed")):
		new_pkmn_ui.pressed.connect(_on_sprite_pressed)


func _on_buy_button_pressed() -> void:
	Events.shop_pkmn_bought.emit(pkmn, gold_cost)
	pkmn_container.queue_free()
	price.queue_free()
	buy_button.queue_free()

func _on_sprite_pressed() -> void:
	if not pkmn:
		print("❌ Tried to emit pkmn_sprite_clicked but pkmn is null!")
		return
	print("🖱️ Clicked on:", pkmn.species_id)
	emit_signal("pkmn_sprite_clicked", pkmn)
