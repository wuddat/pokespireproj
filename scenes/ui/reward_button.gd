class_name RewardButton
extends Button

@export var reward_icon: Texture : set = set_reward_icon
@export var reward_text: String : set = set_reward_text
@export var item_inventory: ItemInventory


@onready var custom_icon: TextureRect = %CustomIcon
@onready var custom_text: Label = %CustomText

const PC_LOGOFF = preload("res://art/sounds/sfx/pc_logoff.wav")

func set_reward_icon(new_icon: Texture) -> void:
	reward_icon = new_icon
	
	if not is_node_ready():
		await ready
	
	custom_icon.texture = reward_icon

func set_reward_text(new_text: String) -> void:
	reward_text = new_text
		
	if not is_node_ready():
		await ready
		
	custom_text.text = reward_text

func _on_pressed() -> void:
	queue_free()
