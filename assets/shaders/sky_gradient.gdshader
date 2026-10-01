shader_type canvas_item;

uniform vec4 zenith_color : source_color = vec4(0.18, 0.35, 0.65, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.72, 0.85, 0.95, 1.0);
uniform vec4 pollution_tint : source_color = vec4(0.8, 0.6, 0.4, 0.0);
uniform float pollution_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    float y = 1.0 - UV.y;
    vec4 base_sky = mix(horizon_color, zenith_color, smoothstep(0.0, 1.0, y));
    vec4 polluted_sky = mix(base_sky, pollution_tint, pollution_amount * (1.0 - y * 0.5));
    COLOR = polluted_sky;
}
