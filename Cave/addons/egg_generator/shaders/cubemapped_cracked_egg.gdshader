shader_type spatial;
render_mode cull_disabled;
// displays a cubemap on an egg
// this is distinct from the other cubemapped egg shader in that it shows the inside of the shell

//** cube map displayed on outside of egg */
uniform samplerCube cube_map:source_color;

//** colour for inside of egg */
uniform vec3 inside_colour:source_color = vec3(0.9);

// value for sampling cubemap
varying vec3 egg_uv;

void vertex() {
	egg_uv = normalize(VERTEX);
}

void fragment() {
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (FRONT_FACING)
		ALBEDO = texture(cube_map, egg_uv).rgb;
	else
		ALBEDO = inside_colour;
}