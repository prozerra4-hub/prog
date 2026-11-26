// SERPENT ARENA — snake skin recolour.
// Every snake draws the same vetted bead artwork (body_segment_blue.png) and this
// shader replaces its hue, so shading, outline, specular and baked shadow are
// pixel-identical across all skins. Low-saturation pixels (specular highlight,
// shadow) keep their neutral colour automatically.
//
// Per-draw vertex colour channels (set via draw_texture_rect modulate):
//   channels.r : brightness multiplier (1 = normal; >1 flash on hit / level-up)
//   channels.g : 0 = primary colour, 1 = band colour
//   channels.b : hurt (0..1) — red tint after being bitten
//   channels.a : alpha
shader_type canvas_item;

// In fragment(), COLOR is already vertex colour * texture, so the raw per-draw
// channels are captured here in vertex() before that multiplication.
varying vec4 channels;

uniform float primary_hue : hint_range(0.0, 1.0) = 0.594;
uniform float primary_sat : hint_range(0.0, 2.0) = 1.0;
uniform float primary_val : hint_range(0.0, 2.0) = 1.0;
uniform float band_hue : hint_range(0.0, 1.0) = 0.12;
uniform float band_sat : hint_range(0.0, 2.0) = 1.0;
uniform float band_val : hint_range(0.0, 2.0) = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
	channels = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(tex.rgb);
	float band = channels.g;
	float hue = mix(primary_hue, band_hue, band);
	float sat = mix(primary_sat, band_sat, band);
	float val = mix(primary_val, band_val, band);
	hsv.x = hue;
	hsv.y = clamp(hsv.y * sat, 0.0, 1.0);
	hsv.z = clamp(hsv.z * val, 0.0, 1.0);
	vec3 rgb = hsv2rgb(hsv);
	// Brightness flash lifts toward white instead of clipping the hue.
	float flash = max(channels.r - 1.0, 0.0);
	rgb = mix(rgb * min(channels.r, 1.0), vec3(1.0), clamp(flash, 0.0, 0.85));
	// Hurt: tint toward a warm red while keeping the shading (luminance) readable.
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(rgb, vec3(1.0, 0.22, 0.18) * (0.55 + 0.8 * lum), clamp(channels.b, 0.0, 1.0) * 0.75);
	COLOR = vec4(rgb, tex.a * channels.a);
}
