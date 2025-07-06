class_name UnitStatusIndicator
extends Control

const CONFUSED_EFFECT = preload("res://art/statuseffects/confused-effect.png")
const SLEEP = preload("res://art/statuseffects/sleep.png")

@onready var status_icon: TextureRect = $StatusIcon

var drift_tween: Tween

func _ready() -> void:
	hide()
	drift_tween = create_tween()
	drift_tween.set_loops()  # infinite loop
	drift_tween.set_trans(Tween.TRANS_SINE)
	drift_tween.set_ease(Tween.EASE_IN_OUT)

	var start_pos := status_icon.position
	var drift_amount := 4.0  # how far it moves left/right
	var rotate_amount := 5.0  # degrees of rotation
	var scale_min := Vector2(0.6, 0.6)
	var scale_max := Vector2(0.8, 0.8)
	var scale_normal := Vector2(0.6, 0.6)  # default

	# Drift left
	drift_tween.tween_property(status_icon, "position", start_pos + Vector2(-drift_amount, 0), 0.4)
	drift_tween.parallel().tween_property(status_icon, "rotation_degrees", -rotate_amount, 0.4)
	drift_tween.parallel().tween_property(status_icon, "scale", scale_min, 0.4)

	# Drift right
	drift_tween.tween_property(status_icon, "position", start_pos + Vector2(drift_amount, 0), 0.8)
	drift_tween.parallel().tween_property(status_icon, "rotation_degrees", rotate_amount, 0.8)
	drift_tween.parallel().tween_property(status_icon, "scale", scale_max, 0.8)

	# Return to center
	drift_tween.tween_property(status_icon, "position", start_pos, 0.4)
	drift_tween.parallel().tween_property(status_icon, "rotation_degrees", 0.0, 0.4)
	drift_tween.parallel().tween_property(status_icon, "scale", scale_normal, 0.4)

func update_status_display(pkmn: Node) -> void:
	#print("[UnitStatusIndicator] update status run")
	if pkmn.status_handler.has_status("confused"):
		#print("[UnitStatusIndicator]confused detected showing effect")
		status_icon.texture = CONFUSED_EFFECT
		show()
		return
	if pkmn.is_asleep == true or pkmn.skip_turn == true:
		#print("[UnitStatusIndicator] sleep detected showing effect")
		status_icon.texture = SLEEP
		show()
		return
	else:
		hide()
		#print("[UnitStatusIndicator] EFFECT HIDDEN")
	
