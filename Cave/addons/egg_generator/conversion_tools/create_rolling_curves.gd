@tool
extends Node
class_name CreateRollingCurve

## mesh we use to generate curve
@export var source_mesh:Mesh

## axis around which mesh will roll
@export var rolling_axis:Vector3 = Vector3.FORWARD

## axis pointing towards ground for default rotation
@export var down_axis:Vector3 = Vector3.DOWN

## range of angles to bake
@export var rotation_range:float = PI

## number of samples along that range to use when making the curves
@export var sample_count:int = 32

## calculate curves now
@export var generate_cuves_now:bool = false:
	set (p_value):
		calculate_curves()

@export_category("Results")
## stored vertical position, relative to ground
@export var heights:Curve

## distance moved from starting position if rolling along flat ground
@export var distance:Curve

@export_category("Testing")

## whether to run testing
@export var testing:bool = false

## current rotation angle in radians
@export var test_value:float = 0.0

## apply target we test on
@export var test_target:PlayRollingCurve


		
func calculate_curves() -> void:
	
	if source_mesh == null:
		print("no source mesh!")
		return
	var vertices:PackedVector3Array
	for i in source_mesh.get_surface_count():
		var mesh_contents:Array = source_mesh.surface_get_arrays(i)
		vertices.append_array(mesh_contents[Mesh.ARRAY_VERTEX])
	
	if heights == null:
		heights = Curve.new()
	
	heights.clear_points()
	heights.min_domain = -rotation_range
	heights.max_domain = rotation_range
	
	
	if distance == null:
		distance = Curve.new()
	
	distance.clear_points()
	distance.min_domain = -rotation_range
	distance.max_domain = rotation_range
	
	calculate_range(1.0, vertices)
	calculate_range(-1.0, vertices)
	
	# set tangents on points aimed toward previous and following points
	set_tangents(heights)
	set_tangents(distance)
	

func calculate_range(sign_mult:float, vertices:PackedVector3Array) -> void:
	var rolling_distance:float = 0
	
	var delta_angle:float = rotation_range / float(sample_count) * sign_mult
	
	var resting_height:float = 0.0
	
	for i in sample_count + 1:
		var t:float = i / float(sample_count)
		var angle:float = lerp(0.0, rotation_range, t) * sign_mult
		# tests in both directions at once, mostly for the sake of accumulated rolling distance
		var test_vector:Vector3 = down_axis.rotated(rolling_axis, angle)
		var furthest_height:float = -INF
		var vector:Vector3
		for vertex in vertices:
			var test_distance:float = test_vector.dot(vertex)
			if test_distance > furthest_height:
				furthest_height = test_distance
				vector = vertex
		
		
		if i == 0:
			resting_height = furthest_height
		
		furthest_height -=  resting_height
		
		# ensure furthest height doesn't exceed range of curve
		if furthest_height < heights.min_value:
			heights.min_value = furthest_height
		if furthest_height > heights.max_value:
			heights.max_value = furthest_height * 1.1
		
		
		heights.add_point(Vector2(angle, furthest_height))
		
		
		distance.add_point(Vector2(angle, rolling_distance))
		
		# approximate distance rotating this point will move the mesh and add it to rolling_distance
		var vect1:Vector3 = vector.rotated(rolling_axis, angle)
		var vect2:Vector3 = vector.rotated(rolling_axis, angle + delta_angle)
		var move_dist:float = (vect1 - vect2).length()
		
		rolling_distance += move_dist * sign_mult
		
		# ensure furthest distance doesn't exceed range of distance curve
		if rolling_distance < distance.min_value:
			distance.min_value = rolling_distance * 1.1
		if rolling_distance > distance.max_value:
			distance.max_value = rolling_distance * 1.1

# set tangents for points based on previous and following points to make the curve smoother 
func set_tangents(curve:Curve) -> void:
	for p in range(1, curve.point_count - 1):
		var prev:Vector2 = curve.get_point_position(p - 1)
		var next:Vector2 = curve.get_point_position(p + 1)
		var diff:= next - prev
		var slope:= diff.y / diff.x
		curve.set_point_left_tangent(p, slope)
		curve.set_point_right_tangent(p, slope)


func _process(_delta: float) -> void:
	if testing && test_target !=null:
		test_target.set_rotation(test_value)
