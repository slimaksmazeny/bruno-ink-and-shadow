// Inkoustový přechod: z prostředku se rozlévá „kaňka“ s nepravidelným okrajem.
// progress 0 = nic, 1 = celá obrazovka v inkoustu. Levné i na mobilu (jen šum v shaderu).
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.05, 0.035, 0.11, 1.0);
uniform vec4 rim_color : source_color = vec4(0.25, 0.55, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float d = length(p);
	float n = noise(UV * 7.0) * 0.32 + noise(UV * 21.0) * 0.12;
	float v = d * 1.25 + n;
	float edge = progress * 2.0;
	float a = 1.0 - smoothstep(edge - 0.04, edge, v);
	float rim = smoothstep(edge - 0.09, edge - 0.04, v) * a;
	COLOR = mix(ink_color, rim_color, rim * 0.8);
	COLOR.a = a;
}
