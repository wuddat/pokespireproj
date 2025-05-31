extends Control


func _on_button_pressed() -> void:
	Events.pokecenter_exited.emit()
