shader_type canvas_item;

uniform float rain_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float rain_speed = 1.2;

void fragment() {
    if (rain_intensity <= 0.01) {
        COLOR = vec4(0.0);
        return;
    }
    
    vec2 uv = UV * vec2(40.0, 12.0);
    uv.y += TIME * rain_speed * 2.0;
    
    float drop = fract(sin(dot(floor(uv), vec2(12.9898, 78.233))) * 43758.5453);
    float streak = smoothstep(0.82, 0.95, drop) * smoothstep(0.0, 0.15, fract(uv.y));
    
    vec4 water_tint = vec4(0.85, 0.92, 1.0, 0.35 * rain_intensity * streak);
    COLOR = water_tint;
}
