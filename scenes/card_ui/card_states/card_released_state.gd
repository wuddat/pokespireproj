extends CardState

var played: bool


func enter() -> void:	
	played = false
	
	if not card_ui.targets.is_empty():
		Events.tooltip_hide_requested.emit()
		played = true
		card_ui.play()
		print("play card for target(s)", card_ui.targets)
	else:
		transition_requested


func on_input(_event: InputEvent) -> void:
	if played:
		return
	
	transition_requested.emit(self, CardState.State.BASE)
