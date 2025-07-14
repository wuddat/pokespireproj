#item_data.gd
extends Node

var items = {}

func _ready():
	var file = FileAccess.open("res://data/items.json",FileAccess.READ)
	var text = file.get_as_text()

	var parsed = JSON.parse_string(text)

	if parsed.has("items"):
		items = parsed["items"]
	else:
		push_error("Missing 'items' key in items.json")


func build_item(id: String) -> Item:
	var raw = items.get(id)
	if raw == null:
		push_error("Item not found: %s" % id)
		return null
	
	var item := Item.new()
	item.id = raw.get("id", id)
	item.name = raw.get("name", "")
	item.description = raw.get("description", "")
	item.icon = load(raw.get("icon_path", ""))
	item.is_consumable = raw.get("is_consumable", true)
	item.usable_in_battle = raw.get("usable_in_battle", true)
	item.category = raw.get("category", "")
	item.type = raw.get("type", "")
	
	if raw.has("status_effects"):
		var raw_ids = raw["status_effects"]
		var typed_ids = Utils.to_typed_string_array(raw_ids)
		item.status_effects.clear()
		item.status_effects.append_array(StatusData.get_status_effects_from_ids(typed_ids))
	
	if raw.has("sound_path"):
		var soundpath = raw["sound_path"]
		item.sound = load(soundpath)
	else:
		var soundpath = "res://art/sounds/move_sfx/splash.mp3"
		item.sound = load(soundpath)
	
	
	var effect_path = raw.get("effect_script", "")
	if effect_path != "":
		item.use_effect = load(effect_path)
		
	return item


func get_random_item() -> Item:
	if items.is_empty():
		push_error("No items loaded in ItemData!")
		return null

	var keys = items.keys()
	var random_key = keys.pick_random()
	return build_item(random_key)
