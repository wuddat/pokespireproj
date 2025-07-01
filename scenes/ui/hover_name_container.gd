extends PanelContainer

@onready var pkmn_name: RichTextLabel = %PkmnName


func _ready() -> void:
	if not is_inside_tree(): await ready
