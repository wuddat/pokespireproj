shader_type canvas_item;

// === UV Transform Controls ===
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform float uv_rotation = 0.0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_pivot = vec2(0.5, 0.5);
uniform bool mirror_horizontal = false;
uniform bool mirror_vertical = false;

// === Color Remapping Controls ===
uniform vec3 target_color : source_color = vec3(1.0, 0.0, 0.0);       // e.g., red
uniform vec3 replacement_color : source_color = vec3(0.0, 1.0, 0.0);  // e.g., green
uniform float tolerance = 0.2;    // How close the pixel must be to target_color
uniform float blend_amount = 1.0; // 0 = no change, 1 = full replacement
uniform bool ignore_black = true; // If true, black (0,0,0) pixels are untouched

void fragment() {
    // === UV Transform ===
    vec2 uv = UV - uv_pivot;
    uv *= uv_scale;

    float cos_r = cos(uv_rotation);
    float sin_r = sin(uv_rotation);
    mat2 rot = mat2(vec2(cos_r, -sin_r), vec2(sin_r, cos_r));
    uv = rot * uv;

    uv += uv_offset + uv_pivot;

    if (mirror_horizontal) uv.x = 1.0 - uv.x;
    if (mirror_vertical) uv.y = 1.0 - uv.y;

    // === Sample Base Color ===
    vec4 base = texture(TEXTURE, uv);
    vec3 color = base.rgb;

    // === Color Matching ===
    float distance = distance(color, target_color);

    // Only apply if within tolerance and (optionally) not black
    bool is_near_target = distance <= tolerance;
    bool is_black = all(lessThan(color, vec3(0.01)));
    
    if (is_near_target && (!ignore_black || !is_black)) {
        color = mix(color, replacement_color, blend_amount);
    }

    COLOR = vec4(color, base.a);
}
