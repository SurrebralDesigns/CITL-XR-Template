shader_type spatial;

group_uniforms Shader.Albedo;
uniform vec4 albedo_color : source_color  = vec4(1.0);
uniform sampler2D albedo_texture;

group_uniforms Shader.Roughness;
uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_roughness : hint_roughness_r;

group_uniforms Shader.Light;
uniform bool use_stepped = true;
uniform float steps = 3.0;
uniform float step_smoothness : hint_range(0.0, 1.0, 0.05) = 0.3;
uniform vec4 shadow_tint : source_color;
uniform float shadow_tint_amount : hint_range(0.0, 1.0, 0.1) = 0.4;

group_uniforms Shader.Specular;
uniform float specular : hint_range(0.0, 1.0, 0.05) = 0.0;

group_uniforms Shader.Normal;
uniform float normal_strength : hint_range(-1.0, 1.0, 0.05) = 0.0;
uniform sampler2D normal_texture;

group_uniforms Shader.Rim;
uniform bool use_rim = true;
uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_amount = 2.0;
uniform float rim_smoothness = 0.2;
uniform float rim_mask_shadow : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float rim_blend : hint_range(0.0, 1.0, 0.05) = 1.0;

group_uniforms Shader.Pattern;
uniform bool use_pattern = true;
uniform sampler2D pattern_texture;
uniform int pattern_uv_mode : hint_enum("UV", "Screen", "Local Screen") = 2;
uniform float pattern_tiling = 32.0;
uniform float pattern_amount : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float pattern_smoothness : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float pattern_blend : hint_range(0.0, 1.0, 0.05) = 0.2;

group_uniforms Shader.Triplanar;
uniform bool use_triplanar = true;
uniform vec3 uv1_scale = vec3(1,1,1);
uniform vec3 uv1_offset;
uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001) = 10.0;

varying vec4 node_position;
varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

vec2 pattern_uv(vec2 uv, vec2 screen_uv){
	vec2 p_uv = uv;
	if(pattern_uv_mode == 1) { p_uv = screen_uv; }
	if(pattern_uv_mode == 2) { p_uv = (screen_uv * 2.0 - 1.0) * node_position.w - node_position.xy; }
	return p_uv;
}

float shape_value(float value, vec2 uv, vec2 screen_size){
	float aspect = screen_size.y / screen_size.x;
	vec2 pattern_uv = uv * pattern_tiling * vec2(1.0, aspect);
	float shadow_pattern = texture(pattern_texture, pattern_uv).r;
	shadow_pattern = clamp(smoothstep(shadow_pattern - pattern_smoothness, shadow_pattern + pattern_smoothness, value + pattern_amount), 0.0, value + pattern_amount);
	return shadow_pattern;
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
    // Sample texture from 3 axes and blend
    vec4 samp = vec4(0.0);
    samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
    samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
    samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
    return samp;
}

void vertex() {
	node_position = (PROJECTION_MATRIX * vec4(NODE_POSITION_VIEW, 1.0));
	vec3 normal = NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);
	
	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

void fragment() {
	vec4 albedo = triplanar_texture(albedo_texture, uv1_power_normal, uv1_triplanar_pos) * albedo_color;
	vec4 normal_map = triplanar_texture(normal_texture, uv1_power_normal, uv1_triplanar_pos);
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	ALBEDO = albedo.rgb;

	NORMAL_MAP = mix(vec3(0.5,0.5,1.0), normal_map.rgb, normal_strength);

	SPECULAR = specular;
}

void light () {
	float ndotl = clamp(dot(NORMAL,LIGHT),0.0,1.0) * ATTENUATION;

	float light = ndotl;

	if(use_stepped){
		float light_mult = light * steps;
		float step_base = floor(light_mult);
		float light_factor = light_mult - step_base;

		light_factor = smoothstep(0.5 - step_smoothness, 0.5 + step_smoothness, light_factor);
		light = (step_base + light_factor) / steps;
	}

	if(use_pattern){
		vec2 p_uv = pattern_uv(UV, SCREEN_UV);

		light = mix(light, shape_value(light, p_uv, VIEWPORT_SIZE), pattern_blend);
	}

	vec3 diffuse = vec3(light) * (LIGHT_COLOR / PI);
	diffuse = (shadow_tint.rgb * (1.0 - (light)) * shadow_tint_amount) + diffuse * light;

	if(use_rim){
		float rim_value = fresnel(rim_amount, NORMAL, VIEW);
		rim_value = smoothstep(0.5 - (rim_smoothness / 2.0), 0.5 + (rim_smoothness / 2.0), rim_value);
		rim_value = mix(rim_value, rim_value * light, rim_mask_shadow);

		diffuse += rim_color.rgb * rim_value * rim_blend;
	}

	DIFFUSE_LIGHT += diffuse;
	SPECULAR_LIGHT += vec3(pow(light, 50.0)) * specular;
}