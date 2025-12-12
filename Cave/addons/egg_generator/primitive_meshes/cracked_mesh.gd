@tool
@icon("res://addons/egg_generator/icons/cracked_egg_icon.svg")
extends PrimitiveMesh
class_name CrackedMesh
# takes a mesh and cracks it into two based on the dividing line

## mesh to crack
@export var source_mesh : Mesh :
	get:
		return source_mesh
	set(p_value):
		source_mesh = p_value
		# TODO is there a way to make this listen for the source mesh being modified?
		source_mesh.ARRAY_BONES
		request_update()

## centre point of where to crack the mesh
@export var mid_point : Vector3 = Vector3.ZERO:
	get:
		return mid_point
	set(p_value):
		mid_point = p_value
		request_update()

## normal of plane of crack
## for example, if crack_normal points up, then it cracks into top and bottom halves
@export var crack_normal : Vector3 = Vector3.UP:
	get:
		return crack_normal
	set(p_value):
		crack_normal = p_value
		request_update()

## flips which side of the crack we keep
@export var flip_side : bool = false:
	get:
		return flip_side
	set(p_value):
		flip_side = p_value
		request_update()


## number of determined points around the crack
@export var points : int = 5:
	get:
		return points
	set(p_value):
		points = p_value
		request_update()

## distance the points should be alllowed to range from centre
@export var jagged_scale : float = 0.4:
	get:
		return jagged_scale
	set(p_value):
		jagged_scale = p_value
		request_update()

## seed used to randomize position of points
@export var random_seed : int = 4:
	get:
		return random_seed
	set(p_value):
		random_seed = p_value
		request_update()

var random_points:Array[float]

# vector we compare other vectors to for the angle
var angle_comparison:Vector3

## creates array of random offsets around crack,
func set_random_points() -> Array[float]:
	random_points.clear()
	var seed:int = random_seed
	var result:Array[float]
	for i in points:
		var rando:int = rand_from_seed(seed)[0]
		# TODO should we deliberately try to zig-zag?
		var offset:float = (rando % 256) / 256.0 - 0.5
		result.append(offset)
		seed += 1
	random_points = result
	return result

# count the number of vertices on each side
func side_count(vertices:PackedVector3Array, indices:PackedInt32Array, i:int) -> int:
	var result:int = 0
	for j in 3:
		if compare_vertex(vertices[indices[i + j]]):
			result += 1
	return result

# gets angle for 
func get_angle(vertex:Vector3) -> float:
	var angle := angle_comparison.signed_angle_to(vertex, crack_normal)
	if angle < 0.0:
		angle += TAU
	return angle

# returns true if vertex is on side of crack we keep
func compare_vertex(vertex:Vector3) -> bool:
	var diff := vertex - mid_point
	var aligned := diff.dot(crack_normal)
	
	var angle := get_angle(vertex)
	var v1:int = floori(angle * points / TAU)
	var v2:int = (v1 + 1) % points
	var t := angle * points / TAU - v1 # position between v1 and v2
	var target:float = clampf(lerp(random_points[v1], random_points[v2], t) * jagged_scale, -0.9, 0.9)
	
	if flip_side:
		return aligned >= target
	else:
		return aligned < target
	return true

func squash_vertices(vertices:PackedVector3Array, normals:PackedVector3Array, indices:Array[int], i:int) -> void:
	var get_count:int = side_count(vertices, indices, i)
	for j in 3:
		var index:= indices[i + j]
		if !compare_vertex(vertices[index]):
			# neighbours
			var n1:Vector3 = vertices[indices[i + (j + 1) % 3]]
			var n2:Vector3 = vertices[indices[i + (j + 2) % 3]]
			
			var normal := normals[indices[i + (j + 1) % 3]]
			if get_count == 1:
				if compare_vertex(n2):
					# only one vertex is good and n2 is it
					n1 = n2
					normal = normals[indices[i + (j + 2) % 3]]
			else:
				# average two vertices
				n1 = (n1 + n2) / 2.0
				normal = normal + normals[indices[i + (j + 2) % 3]] / 2.0
			var t := squash_vertex(vertices[index], n1)
			vertices[index] = lerp(vertices[index], n1, t)
			normals[index] = lerp(normals[index], normal, t)

func find_target(vertex:Vector3) -> float:
	var angle := get_angle(vertex)
	var v1:int = floori(angle * points / TAU)
	var v2:int = (v1 + 1) % points
	var t := angle * points / TAU - v1 # position between v1 and v2
	var target:float = clampf(lerp(random_points[v1], random_points[v2], t) * jagged_scale, -0.9, 0.9)
	return target

# finds t value to position vertex along plane defined by crack, projected towards n1
func squash_vertex(vertex:Vector3, n1:Vector3) -> float:
	var diff := vertex - mid_point
	var aligned := diff.dot(crack_normal)
	var n1_aligned := (n1 - mid_point).dot(crack_normal)
	
	var target := find_target(vertex) 
	var ntarget := find_target(n1)
	# find t value where lerp(target, ntarget, t) matches lerp(aligned, n1_aligned, t)
	# t = (a - c) / (a - b - c + d) where (a - b - c + d) can't be 0
	var t := (target - aligned) / (target - ntarget - aligned + n1_aligned)
	return clampf(t, 0.0, 1.0)

func _create_mesh_array() -> Array:
	# again, assuming a single surface for now,
	# TODO do we need to loop through all surfaces to make this a more general cracking tool
	var mesh_contents:Array = source_mesh.surface_get_arrays(0)
		
	
	# I'm taking a shortcut by assuming these exist if I made the egg mesh
	# some other sources might not have defined Array Index or UVs
	# TODO should I make sure it elegantly handles meshes with no normals or tangents?
	var vertices:PackedVector3Array = mesh_contents[Mesh.ARRAY_VERTEX]
	var normals:PackedVector3Array = mesh_contents[Mesh.ARRAY_NORMAL]
	var uvs:PackedVector2Array = mesh_contents[Mesh.ARRAY_TEX_UV]
	var indices:PackedInt32Array = mesh_contents[Mesh.ARRAY_INDEX]
	var tangents:PackedFloat32Array = mesh_contents[Mesh.ARRAY_TANGENT]
	var triangle_count:int = int(round(indices.size() / 3.0))
	
	# grab verts, uvs, normals, indices, tangents from mesh we mean to crack
	
	var new_indices:Array[int] # indices
	var bridging_triangles:Array[int] # triangles that bridge between one side and the other
	
	if crack_normal != Vector3.RIGHT:
		angle_comparison = crack_normal.cross(Vector3.RIGHT)
	else:
		angle_comparison = crack_normal.cross(Vector3.UP)
	
	set_random_points()
	
	for t in triangle_count:
		var i = t * 3
		# decide what side each vertex is
		var count := side_count(vertices, indices, i)
		if count == 3: # if all vertices are on visible side of crack, put them all in new_indices
			new_indices.append(indices[i])
			new_indices.append(indices[i + 1])
			new_indices.append(indices[i + 2])
		elif count > 0: # if some are on both sides, put them in bridging triangles
			bridging_triangles.append(indices[i])
			bridging_triangles.append(indices[i + 1])
			bridging_triangles.append(indices[i + 2])
		
	# shift the offending vertices on the bridging triangles back towards the visible side of the crack
	for t in bridging_triangles.size() / 3:
		var i = t * 3
		squash_vertices(vertices, normals, bridging_triangles, i)
		
		new_indices.append(bridging_triangles[i])
		new_indices.append(bridging_triangles[i + 1])
		new_indices.append(bridging_triangles[i + 2])
	
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	#arrays[Mesh.ARRAY_TEX_UV2] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(new_indices)
	arrays[Mesh.ARRAY_TANGENT] = tangents

	return arrays
