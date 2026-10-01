shader_type canvas_item;

uniform vec2 lamp_center = vec2(0.5, 0.62);
uniform float lamp_radius = 0.65;
uniform float lamp_intensity = 1.2;
uniform vec4 ambient_darkness : source_color = vec4(0.02, 0.03, 0.06, 0.55);
uniform vec4 lamp_tint : source_color = vec4(1.0, 0.94, 0.82, 0.15);

void fragment() {
    vec2 uv = UV;
    float dist = distance(uv, lamp_center);
    float falloff = smoothstep(lamp_radius, lamp_radius * 0.25, dist);
    
    float dark_alpha = mix(ambient_darkness.a, 0.0, falloff);
    vec3 edge_dark = ambient_darkness.rgb;
    vec3 center_warm = lamp_tint.rgb * lamp_intensity;
    
    vec3 final_rgb = mix(edge_dark, center_warm, falloff);
    float final_alpha = max(dark_alpha, falloff * lamp_tint.a);
    
    COLOR = vec4(final_rgb, final_alpha);
}
