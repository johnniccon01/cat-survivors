shader_type canvas_item;
render_mode unshaded;

// Warm "old printed map" grade for the night town art: cold blues move to
// brown / olive / grey-green, a soft vignette darkens the edges like aged
// paper and a faint static grain breaks up the flat colours.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.4;
uniform float grain : hint_range(0.0, 0.2) = 0.035;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
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
	// Aged-paper vignette.
	vec2 d = UV - 0.5;
	float v = smoothstep(0.30, 0.78, length(d * vec2(1.0, 1.1)));
	m = mix(m, m * vec3(0.55, 0.45, 0.34), v * vignette * 1.6);
	m += (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * grain;
	COLOR = vec4(mix(c, clamp(m, 0.0, 1.0), amount), 1.0);
}
