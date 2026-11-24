// Testovací podlaha s mřížkou po 1 m (silnější čára po 5 m) podle světových souřadnic.
shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.82, 0.84, 0.88, 1.0);
uniform vec4 line_color : source_color = vec4(0.35, 0.38, 0.48, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grid(vec2 p, float spacing, float width) {
	vec2 g = abs(fract(p / spacing - 0.5) - 0.5) * spacing;
	vec2 fw = fwidth(p) * width;
	vec2 l = 1.0 - smoothstep(vec2(0.0), fw, g);
	return max(l.x, l.y);
}

void fragment() {
	vec2 p = world_pos.xz;
	if (abs(NORMAL.y) < 0.5) {
		p = vec2(world_pos.x + world_pos.z, world_pos.y);
	}
	float l1 = grid(p, 1.0, 1.0) * 0.45;
	float l5 = grid(p, 5.0, 2.0);
	ALBEDO = mix(base_color.rgb, line_color.rgb, max(l1, l5));
	ROUGHNESS = 0.9;
}
