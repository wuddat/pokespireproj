class_name SoundPlayer
extends Node

func play(audio: AudioStream, single := false) -> void:
	if not audio:
		return
	
	if single:
		stop()
	
	for player in get_children():
		player = player as AudioStreamPlayer
		
		if not player.playing:
			player.stream = audio
			player.pitch_scale = 1.0  # Reset pitch to default
			player.play()
			break


func pitch_play(audio: AudioStream, min_pitch := 0.95, max_pitch := 1.05, single := false) -> void:
	if not audio:
		return

	if single:
		stop()

	for player in get_children():
		player = player as AudioStreamPlayer

		if not player.playing:
			player.stream = audio
			player.pitch_scale = randf_range(min_pitch, max_pitch)
			player.play()
			break
		#print("we have audio playing!")


func stop() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		player.stop()


func pause() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		if player.playing:
			player.stream_paused = true


func resume() -> void:
	for player in get_children():
		player = player as AudioStreamPlayer
		if player.stream_paused:
			player.stream_paused = false
