shader_type canvas_item;

uniform float dot_density = 120.0;
uniform float contrast = 1.25;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	luma = pow(luma, contrast);

	vec2 grid_uv = fract(UV * dot_density) - vec2(0.5);
	float dist = length(grid_uv);

	float radius = sqrt(1.0 - luma) * 0.55;
	float dot_val = smoothstep(radius, radius - 0.08, dist);

	vec3 paper_tone = vec3(0.92, 0.89, 0.82);
	vec3 ink_tone = vec3(0.12, 0.11, 0.13);

	COLOR = vec4(mix(paper_tone, ink_tone, dot_val), tex.a);
}
