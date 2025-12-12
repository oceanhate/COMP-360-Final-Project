shader_type spatial;
render_mode cull_disabled; // so you can see inside of egg

//** cubemap displayed on shell of egg */
uniform samplerCube cube_map:source_color;

//** distance from 0,0,0 position of mesh that we will split the egg */
uniform float threshold = 0.0;

//** direction it measures that distance threshold */
uniform vec3 direction = vec3(0.0, 0.0, 1.0);

//** colour shown for the white of the egg 
//** use alpha for roughness */
uniform vec4 albumen_colour:source_color = vec4(0.8, 0.8, 0.8, 0.2);

//** colour shown for the yolk of the egg 
//** use alpha for roughness */
uniform vec4 yolk_colour:source_color = vec4(0.7, 0.35, 0.0, 0.9);

//** centre position of yolk in local space of mesh */
uniform vec3 yolk_position = vec3(0.0, -0.065, 0.0);

//** radius of yolk */
uniform float yolk_radius = 0.16;

//** scales values for larger eggs without having to change multiple values */
uniform float scale_egg = 1.0;


// normal of dividing plane in model space
varying vec3 local_plane_normal;

// position of dividing plane in model space
varying vec3 local_pos;

// position of the dividing plane in view space
varying vec3 plane_pos;

// normal of the dividing plane in view space
varying vec3 plane_normal;


// position of yolk in view space
varying vec3 view_yolk_pos;


varying vec3 egg_uv;

void vertex() {
	egg_uv = normalize(VERTEX);
	
	local_plane_normal = normalize(direction);
	local_pos = VERTEX;
	// converts position of plane from model space to view space
	plane_pos =  (VIEW_MATRIX * MODEL_MATRIX * vec4(local_plane_normal * threshold * scale_egg, 1.0)).xyz;
	// converts normal of plane from model space to view space
	plane_normal = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(local_plane_normal, 0.0)).xyz);
	
	view_yolk_pos = (VIEW_MATRIX * MODEL_MATRIX * vec4(yolk_position * scale_egg, 1.0)).xyz;
}

void fragment() {
	// discard removed section of mesh
	if (dot(local_plane_normal, local_pos) > threshold * scale_egg)
		discard;
	
	if (FRONT_FACING) {
		// outside of shell uses cubemap 
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		ALBEDO = texture(cube_map, egg_uv).rgb;
	} else {
		NORMAL = plane_normal;
		// finds intersection of line and plane
		// where plane is dividing plane and line is view direction
		float light_offset = dot((plane_pos - LIGHT_VERTEX), plane_normal) / dot(-VIEW, plane_normal);
		vec3 projected_pos = LIGHT_VERTEX - VIEW * light_offset;
		
		// NOTE: this makes the faked surface receive shadows correctly in Forward+ renderer
		// This won't work with the Compatability render mode, but if you have shadows off it will be fine
		LIGHT_VERTEX = projected_pos;
		
		// set colour and roughnesst based on if it's yolk or albumen
		float yolk_dist = length(projected_pos - view_yolk_pos);
		float yolk_step = smoothstep(yolk_radius * scale_egg * 0.96, yolk_radius * scale_egg, yolk_dist);
		ALBEDO = mix(yolk_colour.rgb, albumen_colour.rgb, yolk_step);
		ROUGHNESS = mix(yolk_colour.a, albumen_colour.a, yolk_step);
	}
}
