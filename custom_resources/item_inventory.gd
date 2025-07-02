#item_inventory.gd
class_name ItemInventory
extends Resource

var items: Array[Item] = []

func add_item(item: Item) -> void:
	items.append(item)

func remove_item(item: Item) -> void:
	items.erase(item)

func use_item(item: Item, targets: Array[Node]) -> void:
	for tar in targets:
		if item.is_consumable:
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
