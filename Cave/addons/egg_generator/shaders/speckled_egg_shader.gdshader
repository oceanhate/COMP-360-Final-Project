shader_type spatial;

// not using the include because 
//#include "egg_speckles.gdshaderinc"



/** 3D noise texture that generates samples
	Try a NoiseTexture3D with FastNoiseLite, 	increasing frequency will make speckles smaller, 0.1 is a good starting point */
uniform sampler3D noise_texture:repeat_disable;

//** main colour of egg */
uniform vec3 base_colour:source_color = vec3(0.85, 0.85, 0.85);

//** colour of speckles */
uniform vec3 speckle_colour:source_color = vec3(0.35, 0.65, 0.91);

/** threshold below which speckles apear, higher values will make more and larger speckles */
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


vec3 get_speckle_colour(vec3 egg_uv) {
	// adjust threshold based on proximity to ends
	float blunt_dist =  pow(smoothstep(blunt_range, 0.0, egg_uv.y), 1.0 / 1.0);
	float point_dist =  pow(smoothstep(point_range, 0.0, 1.0 - egg_uv.y), 1.0 / 1.0);
	float adjusted_threshold = noise_threshold + blunt_dist * blunt_increase + point_dist * point_increase;

	// sample noise texture
	float sample = texture(noise_texture, egg_uv, 0.0).r;

	// apply adjusted threshold to sample
	sample = smoothstep(adjusted_threshold - soften_threshold, adjusted_threshold + soften_threshold, sample);
	// use to pick between speckle and base colours
	return mix(speckle_colour, base_colour, sample);
}

varying vec3 egg_uv;

void vertex() {
	egg_uv = normalize(VERTEX) * 0.5 + vec3(0.5);
}

void fragment() {
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	
	ALBEDO = get_speckle_colour(egg_uv);
}