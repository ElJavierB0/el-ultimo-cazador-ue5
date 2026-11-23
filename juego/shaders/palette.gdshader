shader_type spatial;
// Recolorea la textura del modelo (tono, saturación, luz y matiz) para dar a cada personaje una paleta propia.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float hue = 0.0;
uniform float sat = 1.0;
uniform float light = 1.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float tint_amount = 0.0;
uniform vec3 rim_color : source_color = vec3(0.45, 0.55, 0.85);

vec3 rgb_to_hsl(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float l = (mx + mn) * 0.5;
	float d = mx - mn;
	if (d < 0.0001) {
		return vec3(0.0, 0.0, l);
	}
	float s = l > 0.5 ? d / (2.0 - mx - mn) : d / (mx + mn);
	float h;
	if (mx == c.r) {
		h = (c.g - c.b) / d + (c.g < c.b ? 6.0 : 0.0);
	} else if (mx == c.g) {
		h = (c.b - c.r) / d + 2.0;
	} else {
		h = (c.r - c.g) / d + 4.0;
	}
	return vec3(h / 6.0, s, l);
}

vec3 hsl_to_rgb(vec3 c) {
	vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return c.z + c.y * (rgb - 0.5) * (1.0 - abs(2.0 * c.z - 1.0));
}

void fragment() {
	// Los ajustes se hacen en sRGB (como los ve el ojo) y al final se regresa a lineal.
	vec3 base = pow(texture(albedo_tex, UV).rgb, vec3(1.0 / 2.2));
	vec3 hsl = rgb_to_hsl(base);
	hsl.x = fract(hsl.x + hue + 1.0);
	hsl.y = min(1.0, hsl.y * sat);
	hsl.z = min(1.0, hsl.z * light);
	vec3 col = hsl_to_rgb(hsl);
	col = mix(col, pow(tint, vec3(1.0 / 2.2)) * hsl.z * 2.0, tint_amount);
	ALBEDO = pow(clamp(col, 0.0, 1.0), vec3(2.2));
	ROUGHNESS = 0.85;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim_color * fresnel * 0.22;
}
