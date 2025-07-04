extends Sprite2D

@export var shader_param_name := "target_color"
@export var alpha_threshold := 0.1   # pixels with α ≤ this are ignored
@export var precision := 0.01        # rounding step for colour grouping

func _ready() -> void:
	var shader_mat := material as ShaderMaterial
	if shader_mat == null:
		push_warning("ShaderMaterial not found on this sprite.")
		return

	var img := texture.get_image()
	if img == null:
		push_warning("Could not retrieve image data. Set import “Storage” to Lossless or use ImageTexture.")
		return


	var counts : Dictionary = {}

	for y in img.get_height():
		for x in img.get_width():
			var px : Color = img.get_pixel(x, y)
			if px.a <= alpha_threshold:
				continue

			var key := Color(
				_round(px.r),
				_round(px.g),
				_round(px.b)
			)

			counts[key] = counts.get(key, 0) + 1


	# Sort colors by count descending
	var sorted_colors := counts.keys()
	sorted_colors.sort_custom(func(a, b): return counts[b] - counts[a])

	if sorted_colors.size() >= 2:
		var second_most_common = sorted_colors[1]
		shader_mat.set_shader_parameter(shader_param_name, second_most_common)
		print("🥈 Second most common color:", second_most_common, "count:", counts[second_most_common])
	elif sorted_colors.size() == 1:
		var only_color = sorted_colors[0]
		shader_mat.set_shader_parameter(shader_param_name, only_color)
		print("⚠️ Only one color found:", only_color)
	else:
		print("❌ No valid opaque pixels found.")

func _round(v: float) -> float:
	return round(v / precision) * precision
