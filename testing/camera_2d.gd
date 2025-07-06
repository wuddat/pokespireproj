class_name GameCamera
extends Camera2D

#calls intensity of shake and how long
var shake_intensity: float = 0.0
var active_shake_time: float = 0.0

#controls intensity of shake fade over duration
var shake_decay: float = 5.0

#tracks how long the shake has been going
var shake_time: float = 0.0
var shake_time_speed: float = 20.0

var noise = FastNoiseLite.new()

func _ready() -> void:
	if not Events.camera_shake_requested.is_connected(_on_shake_requested):
		Events.camera_shake_requested.connect(_on_shake_requested)

func _physics_process(delta: float) -> void:
	if active_shake_time > 0:
		shake_time += delta * shake_time_speed
		active_shake_time -= delta
		
		offset = Vector2(
			noise.get_noise_2d(shake_time, 0) * shake_intensity,
			noise.get_noise_2d(0, shake_time) * shake_intensity
		)
		
		shake_intensity = max(shake_intensity - shake_decay * delta, 0)
	else:
		offset = lerp(offset, Vector2.ZERO, 10.5 * delta)


func screen_shake(intensity: int, time: float):
	randomize()
	noise.seed = randi()
	noise.frequency = 2.0
	
	shake_intensity = intensity
	active_shake_time = time
	shake_time = 0.0


func _on_shake_requested(damage: int, intensity: float = 0.2) -> void:
	screen_shake(damage, intensity)
