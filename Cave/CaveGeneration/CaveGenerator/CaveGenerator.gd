extends Node3D

@export var direction_arrow: Node3D          # Arrow3D
@export var voxel_terrain: VoxelTerrain
@export var cave_fog: FogVolume              # CaveFog node
@export var dust_particles: GPUParticles3D   # Player/DustParticles
@export var player: Node3D          # Player instance
@export var player_camera: Camera3D          # Player/Camera
@export var generation_start_marker: Marker3D

@onready var voxel_tool: VoxelTool = voxel_terrain.get_voxel_tool()
@onready var current_walker: Node3D = $CurrentWalker
@onready var end_marker: Node3D = $EndMarker
@onready var win_area: Area3D = $EndMarker/WinArea
@onready var crystal_preload: PackedScene = preload("res://CaveAdditions/Crystal/Crystal.tscn")

@export var random_walk_length: int = 50
@export var removal_size: float = 3.0
@export var ceiling_thickness_m: int = 15

var random_walk_positions: Array[Vector3] = []


func _ready() -> void:
	setup()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("cave_gen"):
		random_walk()


# Hide any MeshInstance3D under a node (recursively)
func _hide_all_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.visible = false
		_hide_all_meshes(child)


func setup() -> void:
	# Reset walker to the start marker
	current_walker.transform = generation_start_marker.transform

	# Hide ALL meshes under the start marker (purple ball etc.)
	if generation_start_marker:
		_hide_all_meshes(generation_start_marker)

	# Hide ALL meshes under the end marker that might be floating above
	if end_marker:
		_hide_all_meshes(end_marker)

	# Arrow starts hidden
	if direction_arrow:
		direction_arrow.visible = false

	# Dust off at start
	if dust_particles:
		dust_particles.emitting = false

	# Fog off at start
	if cave_fog:
		cave_fog.visible = false

	# Win area disabled at start
	if win_area:
		win_area.monitoring = false

	# Hide win label at start
	var win_label := get_node_or_null("/root/TutorialScene/UI/WinLabel")
	if win_label:
		win_label.visible = false


func random_walk() -> void:
	random_walk_positions.clear()

	for i in range(random_walk_length):
		# Move walker
		current_walker.global_position += get_random_direction()

		# Clamp height so we stay under the terrain ceiling
		current_walker.global_position.y = clampf(
			current_walker.global_position.y,
			-1000.0,
			voxel_terrain.generator.height - ceiling_thickness_m
		)

		# Store positions
		random_walk_positions.append(current_walker.global_position)

		# Carve cave + add wall details
		do_sphere_removal()
		var wall_point: Variant = get_random_wall_point()
		if typeof(wall_point) == TYPE_VECTOR3:
			do_sphere_addition(wall_point)

	# --- Place the end marker on top of the cave surface ---

	var end_pos: Vector3 = current_walker.global_position

	# Raycast downward from a bit above the last position
	var ray_start: Vector3 = end_pos + Vector3.UP * 5.0
	var ray_dir: Vector3 = Vector3.DOWN
	var hit: VoxelRaycastResult = voxel_tool.raycast(ray_start, ray_dir, 20.0)

	if hit:
		var surface_pos: Vector3 = hit.position
		var offset: float = 1.2  # push the ball fully out of the surface
		end_pos = surface_pos + hit.normal * offset

	end_marker.global_position = end_pos

	# Add crystals on walls
	wall_additions_pass()

	# 1) Move player to start marker
	if player and generation_start_marker:
		player.global_transform.origin = generation_start_marker.global_position + Vector3(0, 0.5, 0)

	# 2) Switch to player's camera
	if player_camera:
		player_camera.make_current()

	# 3) Turn on cave fog
	if cave_fog:
		cave_fog.visible = true

	# 4) Turn on dust
	if dust_particles:
		dust_particles.emitting = true

	# 5) Enable win trigger
	if win_area:
		win_area.monitoring = true

	# 6) Show compass arrow after 1 second
	if direction_arrow:
		await get_tree().create_timer(1.0).timeout
		direction_arrow.visible = true
		return

	# 7) Show "Find the green ball" text after 1 second
	var win_label := get_node_or_null("/root/TutorialScene/SpiderBot/Camera/UI/WinLabel")
	if win_label:
		await get_tree().create_timer(1.0).timeout
		win_label.visible = true


func wall_additions_pass() -> void:
	for walk_position: Vector3 in random_walk_positions:
		var raycast_result: VoxelRaycastResult = voxel_tool.raycast(
			walk_position,
			get_random_direction(true),
			20
		)
		if raycast_result:
			var new_crystal_instance: Node3D = crystal_preload.instantiate()
			add_child(new_crystal_instance)
			new_crystal_instance.global_position = raycast_result.position
			new_crystal_instance.scale *= randf_range(1.0, 2.0)
			new_crystal_instance.look_at(
				new_crystal_instance.global_position + raycast_result.normal
			)


func get_removal_size(variance: float = 1.0) -> float:
	return removal_size + randf_range(-removal_size * variance, removal_size * variance)


func get_random_wall_point() -> Variant:
	var raycast_result: VoxelRaycastResult = voxel_tool.raycast(
		current_walker.global_position,
		get_random_direction(true),
		20
	)
	if raycast_result:
		return raycast_result.position
	return null


func do_sphere_removal() -> void:
	voxel_tool.mode = VoxelTool.MODE_REMOVE
	voxel_tool.do_sphere(current_walker.global_position, get_removal_size())


func do_sphere_addition(global_point: Vector3 = Vector3.ZERO) -> void:
	voxel_tool.mode = VoxelTool.MODE_ADD
	voxel_tool.do_sphere(global_point, get_removal_size(2.0) / removal_size)


func get_random_direction(use_float: bool = false) -> Vector3:
	var direction_vector: Vector3
	if use_float:
		direction_vector = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
	else:
		direction_vector = Vector3(
			[-1, 0, 1].pick_random(),
			[-1, 0, 1].pick_random(),
			[-1, 0, 1].pick_random()
		)
	return direction_vector
