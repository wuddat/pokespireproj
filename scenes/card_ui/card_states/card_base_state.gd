extends CardState
const CARD_FLICK_1 = preload("res://art/sounds/sfx/card_flick1.mp3")

func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready
	
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()

	card_ui.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_CARDSTYLE)
	card_ui.reparent_requested.emit(card_ui)
	card_ui.pivot_offset = Vector2.ZERO
	Events.tooltip_hide_requested.emit()


func on_gui_input(event: InputEvent) -> void:
	if not card_ui.playable or card_ui.disabled:
		return

	if event.is_action_pressed("left_mouse"):
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardState.State.CLICKED)


func on_mouse_entered() -> void:
	if not card_ui.playable or card_ui.disabled:
		return
	card_ui.card_visuals.panel.set("theme_override_styles/panel", card_ui.HOVER_CARDSTYLE)
	SFXPlayer.pitch_play(CARD_FLICK_1)
	if not is_instance_valid(card_ui.card):
		return
	else:
		card_ui.request_tooltip()
	
	
func on_mouse_exited() -> void:
	if not card_ui.playable or card_ui.disabled:
		return

	card_ui.card_visuals.panel.set("theme_override_styles/panel", card_ui.BASE_CARDSTYLE)
	Events.tooltip_hide_requested.emit()
