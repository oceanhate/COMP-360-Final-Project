extends GPUParticles3D

@export var emission_amount: int = 120          # Less particles
@export var emission_box_size: Vector3 = Vector3(10, 5, 10)
@export var particle_lifetime: float = 3.0
@export var particle_scale: float = 0.03        # Smaller scale
@export var initial_velocity: float = 0.5
@export var particle_color: Color = Color(1, 1, 1, 0.18)  # Very subtle
@export var start_emitting: bool = true


func _ready() -> void:
	amount = emission_amount
	lifetime = particle_lifetime
	emitting = start_emitting
	local_coords = true

	# Process material
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = emission_box_size
	pm.initial_velocity_min = initial_velocity * 0.6
	pm.initial_velocity_max = initial_velocity * 1.4
	pm.gravity = Vector3.ZERO
	pm.scale_min = particle_scale * 0.7
	pm.scale_max = particle_scale * 1.3
	process_material = pm

	# Draw pass: small quad mesh
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.05, 0.05)    # <<< SUPER IMPORTANT: makes dust tiny

	var mat := StandardMaterial3D.new()
	mat.unshaded = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = particle_color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mat

	draw_pass_1 = mesh
