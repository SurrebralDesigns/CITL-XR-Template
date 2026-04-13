shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_test_disabled;
stencil_mode read, compare_equal, 5;
uniform sampler2D texture_albedo : source_color;
uniform vec2 offset = vec2(0.0, 0.0);
uniform float alpha;

void fragment() {

	if (VIEW_INDEX == VIEW_MONO_LEFT) {
		ALBEDO = vec3(texture(texture_albedo, UV - offset).rgb);
		ALPHA = alpha;
	} else if (VIEW_INDEX == VIEW_RIGHT) {
		ALBEDO = vec3(texture(texture_albedo, UV + offset).rgb);
		ALPHA = alpha;
	}
}