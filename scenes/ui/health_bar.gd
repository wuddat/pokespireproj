class_name HealthBar
extends ProgressBar

@export var unit: Node2D

func _ready():
	update()


func update():
	value = unit.health * 100 / unit.max_hp
