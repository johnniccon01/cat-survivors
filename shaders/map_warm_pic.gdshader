shader_type canvas_item;
render_mode unshaded;

// The place picture in the side panel (a crop of the raw town art): the same
// warm "old printed map" grade as map_warm.gdshader, applied to the texture
// itself after a night tint, without vignette or grain.
uniform vec3 night = vec3(0.62, 0.64, 0.76);

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec3 c = t.rgb * night * COLOR.rgb;
	// Blue moves into red/green so navy turns brown-olive, water grey-green.
	vec3 m = vec3(
		0.84 * c.r + 0.10 * c.g + 0.34 * c.b,
		0.04 * c.r + 0.86 * c.g + 0.26 * c.b,
		0.00 * c.r + 0.12 * c.g + 0.40 * c.b);
	// Strongly blue pixels (the harbor) stay a muted grey-teal so water still
	// reads as water next to the brown land.
	float wet = smoothstep(0.02, 0.16, c.b - max(c.r, c.g * 0.9));
	float lc = dot(c, vec3(0.3, 0.55, 0.15));
	m = mix(m, vec3(0.62, 1.0, 0.98) * (0.10 + lc * 1.25), wet * 0.85);
	float l = dot(m, vec3(0.30, 0.55, 0.15));
	m = mix(vec3(l), m, 0.82);
	// Sepia split tone: browner shadows, creamier lights.
	m *= mix(vec3(1.18, 1.0, 0.78), vec3(1.06, 1.0, 0.90), smoothstep(0.1, 0.7, l)) * mix(vec3(1.0), vec3(0.92, 1.02, 1.1), wet);
	m += vec3(0.035, 0.022, 0.006);
	COLOR = vec4(clamp(m, 0.0, 1.0), t.a * COLOR.a);
}
