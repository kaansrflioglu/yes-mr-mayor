shader_type canvas_item;

uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.18, 0.12, 0.9);
uniform float speed : hint_range(0.1, 10.0) = 5.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (pulse_intensity > 0.001) {
		float wave = sin(TIME * speed) * 0.5 + 0.5;
		float pulse = pow(wave, 2.5) * pulse_intensity;
		COLOR = mix(base, vec4(mix(base.rgb, glow_color.rgb, 0.55) + glow_color.rgb * pulse * 0.4, base.a), pulse_intensity);
		COLOR.a = base.a;
	} else {
		COLOR = base;
	}
}
