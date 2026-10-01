shader_type canvas_item;

uniform bool uv_active = false;
uniform sampler2D secret_mask_texture : hint_default_black;
uniform vec4 glow_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform float flicker_speed = 8.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    if (!uv_active) {
        COLOR = base_color;
    } else {
        // Darken regular paper to deep purple/blacklight tone
        vec4 blacklight_tone = base_color * vec4(0.18, 0.14, 0.32, 1.0);
        
        // Sample hidden fluorescent mask
        vec4 mask = texture(secret_mask_texture, UV);
        float pulse = 0.9 + 0.1 * sin(TIME * flicker_speed);
        vec4 fluorescent_emission = mask.r * glow_color * pulse * 2.2;
        
        COLOR = vec4(blacklight_tone.rgb + fluorescent_emission.rgb, base_color.a);
    }
}
