shader_type canvas_item;

uniform float dry_progress : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D paper_grain_texture : hint_default_white;
uniform vec4 ink_color : source_color = vec4(0.1, 0.45, 0.2, 1.0);

void fragment() {
    vec4 decal = texture(TEXTURE, UV);
    if (decal.a < 0.01) {
        discard;
    }
    
    // Sample microscopic paper grain roughness
    vec4 grain = texture(paper_grain_texture, UV * 3.0);
    
    // Wet ink has higher saturation and subtle gloss sheen
    float wetness = 1.0 - dry_progress;
    vec3 wet_ink = ink_color.rgb * 1.25;
    vec3 dry_ink = ink_color.rgb * mix(0.85, 1.0, grain.r);
    
    vec3 current_ink = mix(dry_ink, wet_ink, wetness);
    
    // Ink bleeding along paper fibers at edges
    float bleed_alpha = smoothstep(0.1, 0.5, decal.a + (grain.g - 0.5) * 0.15 * dry_progress);
    
    COLOR = vec4(current_ink, decal.a * bleed_alpha);
}
