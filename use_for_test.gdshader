shader_type canvas_item;

// Editable properties
uniform float pixel_sc : hint_range(1.0, 512.0) = 32.0;
uniform float bender : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_mod : hint_range(0.0, 1.0) = 1.0; // transparency control

void fragment() {
	float pixel_size = 1.0 / pixel_sc;

	vec2 snapped_uv = floor(UV * pixel_sc) / pixel_sc + (pixel_size / 2.0);

	vec4 color_1 = texture(TEXTURE, snapped_uv);
	color_1.a = step(0.5, color_1.a);

	vec3 color_c = color_1.rgb;
	vec3 color_up = texture(TEXTURE, snapped_uv + vec2(0.0, pixel_size)).rgb;
	vec3 color_down = texture(TEXTURE, snapped_uv - vec2(0.0, pixel_size)).rgb;
	vec3 color_right = texture(TEXTURE, snapped_uv + vec2(pixel_size, 0.0)).rgb;
	vec3 color_left = texture(TEXTURE, snapped_uv - vec2(pixel_size, 0.0)).rgb;
	vec3 color_up_right = texture(TEXTURE, snapped_uv + vec2(pixel_size, pixel_size)).rgb;
	vec3 color_down_right = texture(TEXTURE, snapped_uv + vec2(pixel_size, -pixel_size)).rgb;
	vec3 color_down_left = texture(TEXTURE, snapped_uv + vec2(-pixel_size, -pixel_size)).rgb;
	vec3 color_up_left = texture(TEXTURE, snapped_uv + vec2(-pixel_size, pixel_size)).rgb;

	float l1 = length(color_c - color_up);
	float l2 = length(color_c - color_down);
	float l3 = length(color_c - color_right);
	float l4 = length(color_c - color_left);
	float l5 = length(color_c - color_up_right);
	float l6 = length(color_c - color_down_right);
	float l7 = length(color_c - color_down_left);
	float l8 = length(color_c - color_up_left);

	float min_l = min(min(min(l1, l2), min(l3, l4)), min(min(l5, l6), min(l7, l8)));

	vec4 result = color_1;
	result = abs(min_l - l1) < 0.00001 ? vec4(mix(color_up, color_c, bender), result.a) : result;
	result = abs(min_l - l2) < 0.00001 ? vec4(mix(color_down, result.rgb, bender), result.a) : result;
	result = abs(min_l - l3) < 0.00001 ? vec4(mix(color_right, result.rgb, bender), result.a) : result;
	result = abs(min_l - l4) < 0.00001 ? vec4(mix(color_left, result.rgb, bender), result.a) : result;
	result = abs(min_l - l5) < 0.00001 ? vec4(mix(color_up_right, result.rgb, bender), result.a) : result;
	result = abs(min_l - l6) < 0.00001 ? vec4(mix(color_down_right, result.rgb, bender), result.a) : result;
	result = abs(min_l - l7) < 0.00001 ? vec4(mix(color_down_left, result.rgb, bender), result.a) : result;
	result = abs(min_l - l8) < 0.00001 ? vec4(mix(color_up_left, result.rgb, bender), result.a) : result;

	// Apply final alpha modulation
	result.a *= alpha_mod;
	COLOR = result;
}
