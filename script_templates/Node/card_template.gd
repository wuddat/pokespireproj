# meta-name: Card Logic
# meta-description: What happens when card is played
extends Card

@export var optional_sound: AudioStream


func apply_effects(targets: Array[Node]) -> void:
	print("the card has been played!")
	print("Targets: " % targets)
