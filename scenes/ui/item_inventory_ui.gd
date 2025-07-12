#item_inventory_ui.gd
extends HBoxContainer

const EMPTY_ICON = preload("res://art/dottedline.png")

enum State {IDLE, SELECTING_TARGET}

var current_state := State.IDLE
var pending_item: Item = null


@onready var slot_1: TextureButton = %Slot1
@onready var slot_2: TextureButton = %Slot2
@onready var slot_3: TextureButton = %Slot3
@onready var item_inventory_ui: HBoxContainer = $"."

var char_stats: CharacterStats
var btn_slots: Array[TextureButton] = []

func _ready() -> void:
	if char_stats == null:
		await get_tree().process_frame
	if not Events.item_used.is_connected(_on_item_used):
		Events.item_used.connect(_on_item_used)
	if not Events.item_added.is_connected(_on_item_added):
		Events.item_added.connect(_on_item_added)
	
	btn_slots = [slot_1,slot_2,slot_3]
	for slot in btn_slots:
		slot.get_child(0).hide()
	
	update_items()


func update_items() -> void:
	if char_stats.item_inventory.size() != 0:
		for i in range(char_stats.item_inventory.size()):
			if is_instance_valid(char_stats.item_inventory.items[i]):
				btn_slots[i].texture_normal = char_stats.item_inventory.items[i].icon
				if not btn_slots[i].pressed.is_connected(_on_item_pressed):
					btn_slots[i].pressed.connect(_on_item_pressed.bind(i))
				btn_slots[i].get_child(0).text = str(char_stats.item_inventory.items[i].quantity)
				if char_stats.item_inventory.items[i].quantity <=1:
					btn_slots[i].get_child(0).hide()
				else: btn_slots[i].get_child(0).show()
				char_stats.item_inventory.items[i].current_position = btn_slots[i].global_position
			else: btn_slots[i].texture_normal = EMPTY_ICON
	else:
		for slot in btn_slots:
			slot.texture_normal = EMPTY_ICON

func reset_item_use_state() -> void:
	current_state = State.IDLE
	pending_item = null


func _on_item_used(current_item: Item) -> void:
	print("used %s!" % current_item.name)
	char_stats.item_inventory.use_item(current_item, current_item.targets)
	update_items()


func _on_item_pressed(index: int) -> void:
	var itm = char_stats.item_inventory.items[index]
	print("item has been pressed: %s" % itm.name)
	if itm.usable_in_battle:
		current_state = State.SELECTING_TARGET
		pending_item = itm
		Events.item_aim_started.emit(itm)


func _on_item_added(_itm: Item) -> void:
	update_items()

func on_enemy_clicked(enemy: Node) -> void:
	if current_state == State.SELECTING_TARGET and pending_item:
		char_stats.item_inventory.use_item(pending_item, [enemy])
		reset_item_use_state()
		Events.item_aim_ended.emit()


func get_item_origin_position() -> Vector2:
	var slot_index := char_stats.item_inventory.items.find(pending_item)
	if slot_index == -1:
		return Vector2.ZERO
	var button := btn_slots[slot_index]
	return button.get_global_position() + button.size / 2.0


func get_tooltip_data() -> Dictionary:
	var intent_description: String = ""
	return {
		"header": "[color=tan]Items[/color]:",
		"description": "When  you  find  some\nyou  can  use  them  to\ndo stuff!"
	}
