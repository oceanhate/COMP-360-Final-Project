extends Node3D

@export var target: Node3D   # EndMarker (green ball)

# Local position relative to the camera: right, up, towards camera
@export var local_offset: Vector3 = Vector3(1.5, 1, -2.0)

func _process(delta: float) -> void:
	# 1) ALWAYS keep Arrow3D at the same place in camera space
	position = local_offset

	# 2) Rotate so the tip points to the target
	if target == null:
		return

	var from: Vector3 = global_transform.origin
	var dir: Vector3 = (target.global_position - from).normalized()
	look_at(from + dir, Vector3.UP)
