shader_type canvas_item;

// Warm "old print" grade for the title night art: the blue-purple sky and
// buildings turn dark sepia brown, warm pixels (lit windows, the moon) keep
// their colour, a soft vignette and a faint grain finish it.
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float grain : hint_range(0.0, 0.2) = 0.03;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float l = dot(c, vec3(0.30, 0.55, 0.15));
	float cold = smoothstep(0.0, 0.10, c.b - c.r * 0.9);
	vec3 sepia = mix(vec3(0.13, 0.085, 0.055), vec3(0.72, 0.52, 0.32), pow(smoothstep(0.0, 0.8, l), 0.75));
	sepia = mix(sepia, vec3(1.0, 0.93, 0.74), smoothstep(0.72, 1.0, l));
	vec3 warm = c * vec3(1.06, 1.0, 0.86);
	vec3 m = mix(warm, sepia, cold);
	vec2 d = UV - 0.5;
	float v = smoothstep(0.30, 0.80, length(d * vec2(1.0, 1.1)));
	m = mix(m, m * vec3(0.55, 0.45, 0.34), v * vignette * 1.6);
	m += (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * grain;
	COLOR = vec4(clamp(m, 0.0, 1.0), texture(TEXTURE, UV).a);
}
