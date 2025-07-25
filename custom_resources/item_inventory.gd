#item_inventory.gd
class_name ItemInventory
extends Resource

@export var items: Array[Item] = []

func add_item(item: Item) -> void:
	var existing_item: Item = null
	for itm in items:
		if itm.id == item.id:
			existing_item = itm
			break
	if existing_item:
		existing_item.quantity += 1
		print("INCREASED QUANTITY of item: %s (now %d)" % [existing_item.name, existing_item.quantity])
		Events.item_added.emit(existing_item)
	else:
		items.append(item)
		print("ADDED NEW ITEM: %s" % item.name)
		Events.item_added.emit(item)
	for i in items:
		print("%s x%d" % [i.name, i.quantity])

func remove_item(item: Item) -> void:
	items.erase(item)

func use_item(item: Item, targets: Array[Node]) -> void:
	for tar in targets:
		if item.is_consumable:
			if item.id == "pokeball" and tar.is_trainer_pkmn == true:
				Events.battle_text_requested.emit("You can't catch trainer's pokemon!")
			else:
				print("item used on %s!" % tar.name)
				if item.status_effects:
					for status_effect in item.status_effects:
						var stat_effect := StatusEffect.new()
						stat_effect.source = null
						stat_effect.status = status_effect.duplicate()
						stat_effect.execute(targets)

	if item.is_consumable:
		item.quantity -= 1
		print("Remaining quantity of %s: %d" % [item.name, item.quantity])
		
		if item.quantity <= 0:
			remove_item(item)
			print("%s removed from inventory (quantity 0)" % item.name)
	SFXPlayer.play(item.sound)

func size() -> int:
	return items.size()
