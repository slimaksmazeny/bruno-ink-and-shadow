// Komiksový vzhled přes celou obrazovku: inkoustové obrysy z hloubky + světlo po stupních
// + jemné papírové zrno. Vlastní shader (žádný převzatý kód). Běží na Forward+ i Mobile.
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

uniform vec4 ink_color : source_color = vec4(0.06, 0.04, 0.10, 1.0);
// Tloušťka čáry v pixelech.
uniform float line_width : hint_range(0.5, 4.0) = 1.4;
// Citlivost na skoky v hloubce (relativně ke vzdálenosti).
uniform float depth_threshold : hint_range(0.001, 0.2) = 0.035;
// Počet stupňů světla (komiksové stínování).
uniform float bands : hint_range(2.0, 8.0) = 4.0;
// 0 = původní barvy, 1 = plné stupně.
uniform float band_strength : hint_range(0.0, 1.0) = 0.65;
uniform float saturation : hint_range(0.5, 1.6) = 1.15;
uniform float grain : hint_range(0.0, 0.1) = 0.004;
// Obrysy daleko slábnou, ať horizont není čmáranice.
uniform float fade_start = 35.0;
uniform float fade_end = 90.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = line_width / VIEWPORT_SIZE;
	vec3 col = texture(screen_tex, uv).rgb;

	// Hrany z hloubky (kříž 4 sousedů).
	float c = linear_depth(uv, INV_PROJECTION_MATRIX);
	float l = linear_depth(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float r = linear_depth(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float u = linear_depth(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float d = linear_depth(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float diff = max(max(abs(l - c), abs(r - c)), max(abs(u - c), abs(d - c)));
	float edge = smoothstep(depth_threshold, depth_threshold * 2.5, diff / max(c, 0.5));
	edge *= 1.0 - smoothstep(fade_start, fade_end, c);

	// Světlo po stupních (zachová odstín, kvantuje jas).
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float q = floor(lum * bands + 0.5) / bands;
	// Omezit zesílení/ztlumení, ať tmavé barvy „nepřepálí“ do sytých odstínů.
	float ratio = clamp(q / max(lum, 0.001), 0.7, 1.3);
	vec3 banded = col * ratio;
	col = mix(col, banded, band_strength);
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(g), col, saturation);

	// Papírové zrno.
	col += (hash(uv * VIEWPORT_SIZE + TIME * 0.0) - 0.5) * grain;

	ALBEDO = mix(col, ink_color.rgb, edge * ink_color.a);
}
