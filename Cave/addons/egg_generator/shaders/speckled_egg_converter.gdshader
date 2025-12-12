shader_type spatial;
render_mode unshaded, cull_disabled;
// made to help convert speckled_egg_shader into a flat texture
// used by ConvertSpeckledMaterialToCubemap


/** 3D noise texture that generates samples
	Try a NoiseTexture3D with FastNoiseLite, 	increasing frequency will make speckles smaller, 0.1 is a good starting point */
uniform sampler3D noise_texture:repeat_disable;

uniform vec3 base_colour:source_color = vec3(0.85, 0.85, 0.85);

uniform vec3 speckle_colour:source_color = vec3(0.35, 0.65, 0.91);

/** threshold below which speckles apear */
uniform float noise_threshold:hint_range(-0.2, 1.0, 0.01) = 0.2;

/** range to soften that threshold */
uniform float soften_threshold:hint_range(0.01, 0.5, 0.01) = 0.1;

/** bonus on threshold to make speckles appear on blunt end */
uniform float blunt_increase:hint_range(0.0, 0.5, 0.01) = 0.0;

/** range from blunt end to add speckles */
uniform float blunt_range:hint_range(0.0, 0.5, 0.01) = 0.0;

/**  bonus on threshold to make speckles appear on pointed end */
uniform float point_increase:hint_range(0.0, 0.5, 0.01) = 0.0;

/** range from point end to add speckles */
uniform float point_range:hint_range(0.0, 0.5, 0.01) = 0.0;


varying vec3 direction_vector;

void vertex() {
	direction_vector = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - CAMERA_POSITION_WORLD;
}

void fragment() {
	vec3 egg_uv = normalize(direction_vector) * 0.5 + vec3(0.5);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;

	// adjust threshold based on proximity to ends
	float blunt_dist =  pow(smoothstep(blunt_range, 0.0, egg_uv.y), 1.0 / 1.0);
	float point_dist =  pow(smoothstep(point_range, 0.0, 1.0 - egg_uv.y), 1.0 / 1.0);
	float adjusted_threshold = noise_threshold + blunt_dist * blunt_increase + point_dist * point_increase;

	// sample noise texture
	float sample = texture(noise_texture, egg_uv, 0.0).r;

	// apply adjusted threshold to sample
	sample = smoothstep(adjusted_threshold - soften_threshold, adjusted_threshold + soften_threshold, sample);
	// use to pick between speckle and base colours
	ALBEDO = mix(speckle_colour, base_colour, sample);
}