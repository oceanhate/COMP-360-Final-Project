shader_type spatial;
// displays a cubemap on an egg
// I guess you could use it on something other than eggs, it projects the cubemap based on local vertex position

//** cubemap displayed on egg */
uniform samplerCube cube_map:source_color;

// value for sampling cubemap
varying vec3 egg_uv;

void vertex() {
	egg_uv = normalize(VERTEX);
}

void fragment() {
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALBEDO = texture(cube_map, egg_uv).rgb;
}