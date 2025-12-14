@tool
@icon("res://addons/egg_generator/icons/egg_icon.svg")
extends PrimitiveMesh
class_name TwoRadiiEggMesh
# defines an egg shape based on two radii


## overall length of the egg from tip to tip
@export var length : float = 0.6 :
	get:
		return length
	set(p_value):
		length = p_value
		request_update()

## radius of smaller end, relative to half length
@export_range(0.0, 1.2, 0.01) var rad_point : float = 0.45 :
	get:
		return rad_point
	set(p_value):
		rad_point = min(p_value, rad_blunt) # prevent it being larger than rad blunt
		request_update()

## radius of larger end, relative to half length
@export_range(0.0, 1.2, 0.01) var rad_blunt : float = 0.9 :
	get:
		return rad_blunt
	set(p_value):
		rad_blunt = max(p_value, rad_point) # can't be smaller than point
		request_update()


## lower values will make the tips more pointy, higher values more blunt
@export_range(1.5, 4.0, 0.01) var pow_curve : float = 2.2 :
	get:
		return pow_curve
	set(p_value):
		pow_curve = p_value
		request_update()


## number of segments to divide along the length
@export var segments_length : int = 8:
	get:
		return segments_length
	set(p_value):
		segments_length = p_value
		request_update()

## number of segments to divide around each ring
@export var segments_around : int = 16:
	get:
		return segments_around
	set(p_value):
		segments_around = p_value
		request_update()

## duplicates vertex at tips for better tangents
@export var ensure_tangents_at_tip : bool = false:
	get:
		return ensure_tangents_at_tip
	set(p_value):
		ensure_tangents_at_tip = p_value
		request_update()

## make egg hollow
@export var hollow : bool = false:
	get:
		return hollow
	set(p_value):
		hollow = p_value
		request_update()


## thickness of shell as a 10th of a percent of the length
@export_range(1.0, 100.0, 0.1) var shell_thickness : float = 15.0:
	get:
		return shell_thickness
	set(p_value):
		shell_thickness = p_value
		request_update()


func add_triangle_vertices(verts : PackedVector3Array, p_v0 : Vector3, p_v1 : Vector3, p_v2 : Vector3) -> void:
	verts.push_back(p_v0)
	verts.push_back(p_v1)
	verts.push_back(p_v2)


# get y value for a given t range 0.0 to 1.0
func get_surface(t:float) -> Vector3:
	var result:Vector3 = Vector3.ZERO
	
	var ease_t:float = ease(t, -pow_curve)

	# start and end position that circle ranges through
	var centre_start:float = (1.0 - rad_point * 0.5)
	var centre_end:float = rad_blunt * 0.5
	
	# position of circle sliding from one end to the other
	var current_pos:float = lerp(centre_start, centre_end, ease_t)
	
	# size of radius has to be rad_point at t = 0, and rad_blunt at end
	var current_rad:float = lerp(rad_point, rad_blunt, ease_t) * 0.5
	
	# adjust angle so it's half-way at d_pos
	# angle from radius centre to surface
	# ranges from 0 to PI, but needs 0.5 at the same time as 
	var angle:float = t * PI # lerp(0.5 * PI, t * PI, d_dist)
	
	result = Vector3(sin(angle) * current_rad, current_pos + cos(angle) * current_rad - 0.5, 0.0)
	
	return result * length

# get normal for a given t range 0.0 to 1.0
func get_normal(t:float) -> Vector3:
	# does it dumb way by getting two values and finding difference
	const small_offset:float = 0.01
	var earlier:Vector3 = get_surface(t - small_offset)
	var next:Vector3 = get_surface(t + small_offset)
	var tangent:Vector3 = (next - earlier).normalized()
	return tangent.cross(Vector3(0, 0, -1))
	#return Vector3(cos(angle), sin(angle), 0.0)

# generates a single ring of vertices for a given x
func generate_ring_of_vertices(t:float, verts : PackedVector3Array, normals : PackedVector3Array, uvs : PackedVector2Array, tangents : PackedFloat32Array) -> void:
	var unrotated_normal:Vector3 = get_normal(t)
	var unrotated_surface:Vector3 = get_surface(t)
	var unrotated_tangent:Vector3 = Vector3.RIGHT
	for angle_index in range(segments_around + 1):
		var angle:float = angle_index / float(segments_around) * TAU
		var rotation:Quaternion = Quaternion.from_euler(Vector3(0.0, -angle, 0.0))
		verts.append(rotation * unrotated_surface)
		normals.append(rotation * unrotated_normal)
		uvs.append(Vector2(angle_index / float(segments_around), t))
		var rotated_tangent := rotation * unrotated_tangent
		tangents.append_array([rotated_tangent.x, rotated_tangent.y, rotated_tangent.z, 1.0])
		# add to list of vertices

# adds vertex at very top of blunt end
func add_blunt_end_vertex(verts : PackedVector3Array, normals : PackedVector3Array, uvs : PackedVector2Array, tangents : PackedFloat32Array) -> void:
	var normal:Vector3 = Vector3(0.0, -1.0, 0.0)
	var surface:Vector3 = get_surface(1.0)
	verts.append(surface)
	normals.append(normal)
	uvs.append(Vector2(0.5, 1.0))
	tangents.append_array([1.0, 0.0, 0.0, 1.0])

# adds vertex at very top of pointed end
func add_pointed_end_vertex(verts : PackedVector3Array, normals : PackedVector3Array, uvs : PackedVector2Array, tangents : PackedFloat32Array) -> void:
	var normal:Vector3 = Vector3(0.0, 1.0, 0.0)
	var surface:Vector3 = get_surface(0.0)
	verts.append(surface)
	normals.append(normal)
	uvs.append(Vector2(0.5, 0.0))
	tangents.append_array([1.0, 0.0, 0.0, 1.0])

# generates a vector along x and y converted to angles
func generate_vector(x:float, y:float) -> Vector3:
	var rx:float = (x - 0.5) * PI / 2.0
	var ry:float = (y - 0.5) * PI / 2.0
	var result:Vector3 = Vector3(-sin(rx) * cos(ry), - cos(rx) * sin(ry), cos(rx) * cos(ry))
	return result.normalized()

# adds the indices that will connect one ring of vertices to the ring before it
func add_ring_of_indices(last_index:int, indices:PackedInt32Array, skip:int = -1) -> void:
	for xx in range(0, segments_around):
		# two triangles
		var s:int = xx + last_index
		if skip != 0:
			indices.append_array([s, s + 1, s - segments_around])
		if skip != 1:
			indices.append_array([s, s - segments_around, s - segments_around - 1])

# joins one row of vertices to the vertex right at the blunt end
func add_blunt_end_indices(last_index:int, tip_index:int, indices:PackedInt32Array) -> void:
	for xx in range(0, segments_around):
		var s:int = xx + last_index
		indices.append_array([tip_index, s, s - 1])

# joins one row of vertices to the vertex right at the pointed end
func add_pointed_end_indices(last_index:int, tip_index:int, indices:PackedInt32Array) -> void:
	for xx in range(0, segments_around):
		var s:int = xx + last_index
		indices.append_array([tip_index, s, s + 1])


		

# generates one of six faces of a supersphere
func generate_egg_main(verts : PackedVector3Array, normals : PackedVector3Array, uvs : PackedVector2Array, indices : PackedInt32Array, tangents : PackedFloat32Array) -> void:
	# handle pointed end as special case with one vertex on the tip
	if ensure_tangents_at_tip:
		generate_ring_of_vertices(0.0, verts, normals, uvs, tangents)
		generate_ring_of_vertices(1.0 / float(segments_length), verts, normals, uvs, tangents) # generate first ring
		add_ring_of_indices(verts.size() - 1 - segments_around, indices, 1)
	else:
		add_pointed_end_vertex(verts, normals, uvs, tangents) # generate one vertex at the tip
		generate_ring_of_vertices(1.0 / float(segments_length), verts, normals, uvs, tangents) # generate first ring
		add_pointed_end_indices(1, 0, indices) # add triangles joining that vertex to the first ring
	
	for xx in range(2, segments_length):
		# generate a ring of vertice
		generate_ring_of_vertices(float(xx) / float(segments_length), verts, normals, uvs, tangents)
		# add indices for triangles, joining that ring to the previous ring
		add_ring_of_indices(verts.size() - 1 - segments_around, indices)
	
	if ensure_tangents_at_tip:
		generate_ring_of_vertices(1.0, verts, normals, uvs, tangents)
		add_ring_of_indices(verts.size() - 1 - segments_around, indices, 0)
	else:
		# handle blunt end as special case with one vertex on the tip
		add_blunt_end_vertex(verts, normals, uvs, tangents)
		# add triangles joining that vertex to the last ring
		add_blunt_end_indices(verts.size() - 1 - segments_around, verts.size() - 1, indices)
	

func generate_inner_shell(verts : PackedVector3Array, normals : PackedVector3Array, uvs : PackedVector2Array, indices : PackedInt32Array, tangents : PackedFloat32Array) -> void:
	var vert_count:int = verts.size()
	
	# duplicate verts and shift them inwards according to normals, multiplied by shell thickness
	var verts_copy = verts.duplicate()
	for i in verts.size():
		verts_copy.set(i, verts[i] - normals[i] * shell_thickness * length / 1000.0)
	verts.append_array(verts_copy)
	
	# scale uvs vertically by half
	for i in uvs.size():
		uvs.set(i, uvs[i] * Vector2(1.0, 0.5))
	
	# duplicate uvs and shift them down by 0.5
	var uvs_copy := uvs.duplicate()
	for i in uvs_copy.size():
		uvs_copy.set(i, uvs_copy[i] * Vector2(-1.0, 1.0) + Vector2(0.0, 0.5))
	uvs.append_array(uvs_copy)
	
	# duplicate indices and invert each triangle
	var indices_copy := indices.duplicate()
	for i in indices_copy.size() / 3:
		indices_copy.set(i * 3, indices[i * 3] + vert_count)
		indices_copy.set(i * 3 + 1, indices[i * 3 + 2] + vert_count)
		indices_copy.set(i * 3 + 2, indices[i * 3 + 1] + vert_count)
	indices.append_array(indices_copy)
	
	# duplicate and flip normals
	var normals_copy := normals.duplicate()
	for i in normals_copy.size():
		normals_copy.set(i, normals[i] * -Vector3.ONE)
	normals.append_array(normals_copy)
	
	# duplicate and flip tangents
	var tangents_copy := tangents.duplicate()
	for i in tangents_copy.size() / 4:
		tangents_copy.set(i * 4, tangents_copy[i * 4] * -1.0)
		tangents_copy.set(i * 4 + 1, tangents_copy[i * 4 + 1] * -1.0)
		tangents_copy.set(i * 4 + 2, tangents_copy[i * 4 + 2] * -1.0)
	tangents.append_array(tangents_copy)
	
	

func _create_mesh_array() -> Array:

	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var tangents := PackedFloat32Array()
	
	generate_egg_main(verts, normals, uvs, indices, tangents)
	
	if hollow:
		generate_inner_shell(verts, normals, uvs, indices, tangents)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	#arrays[Mesh.ARRAY_TEX_UV2] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TANGENT] = tangents

	return arrays
