#extends Control
#
#@export var bob_distance: float = 8.0            # Vertical bobbing distance
#@export var bob_duration: float = 1.5            # Total time for full bob cycle
#@export var rotation_amount: float = 3.0         # Max degrees to rotate left/right
#
#var original_position: Vector2
#var tween: Tween
#
#func _ready():
	#original_position = position
	#rotation_degrees = 0
	#_start_bobbing()
#
#func _start_bobbing():
	#tween = create_tween()
	#tween.set_loops()
#
	## === Bob Down + Rotate Right (at the same time) ===
	#tween.tween_property(self, "position", original_position + Vector2(0, bob_distance), bob_duration / 2) \
		#.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#tween.parallel().tween_property(self, "rotation_degrees", rotation_amount, bob_duration / 2) \
		#.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#
	## === Bob Up + Rotate Left ===
	#tween.tween_property(self, "position", original_position - Vector2(0, bob_distance), bob_duration) \
		#.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#tween.parallel().tween_property(self, "rotation_degrees", -rotation_amount, bob_duration) \
		#.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#
	## === Return to Center ===
	#tween.tween_property(self, "position", original_position, bob_duration / 2) \
		#.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#tween.parallel().tween_property(self, "rotation_degrees", 0.0, bob_duration / 2) \
		#.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#
## 💡 Force pixel alignment every frame to avoid artifacts
#func _process(_delta):
	#position = position.round()
	#rotation_degrees = round(rotation_degrees)
