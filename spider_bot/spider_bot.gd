extends Node3D

@export var move_speed: float = 3.0
@export var turn_speed: float = 1.5
@export var ground_offset: float = 4.0
@export var spider_scale: float = .1

@onready var fl_leg = $FrontLeftIKTarget
@onready var fr_leg = $FrontRightIKTarget
@onready var bl_leg = $BackLeftIKTarget
@onready var br_leg = $BackRightIKTarget

@onready var arm: SpringArm3D = $SpringArm3D

@onready var move_sound: AudioStreamPlayer3D = $MoveSound
var last_position: Vector3



func _ready():
	# Apply scale ONCE (safe)
	scale = Vector3.ONE * spider_scale

	# Adjust ground offset for size
	ground_offset *= spider_scale
	last_position = global_position

func _process(delta):
	# --- Align body to ground ---
	var plane1 = Plane(
		bl_leg.global_position,
		fl_leg.global_position,
		fr_leg.global_position
	)

	var plane2 = Plane(
		fr_leg.global_position,
		br_leg.global_position,
		bl_leg.global_position
	)

	var avg_normal = ((plane1.normal + plane2.normal) * 0.5).normalized()

	var target_basis = _basis_from_normal(avg_normal)

	var current_q = transform.basis.get_rotation_quaternion()
	var target_q = target_basis.get_rotation_quaternion()

	transform.basis = Basis(
		current_q.slerp(target_q, move_speed * delta)
		)


	# --- Position body above ground ---
	var avg = (
		fl_leg.position +
		fr_leg.position +
		bl_leg.position +
		br_leg.position
	) * 0.255

	var target_pos = avg + transform.basis.y * ground_offset
	var distance = transform.basis.y.dot(target_pos - position)

	position = lerp(
		position,
		position + transform.basis.y * distance,
		move_speed * delta
	)

	_handle_movement(delta)

	# Camera follow 
	arm.global_transform.origin = global_transform.origin
	arm.global_rotation = global_rotation

	# Camera offset
	arm.rotation_degrees.y = 90

	# Camera Distance
	arm.spring_length = -3.0 

	# Offset 
	arm.transform.origin = Vector3(3, 5, 6) 

	# Camera Tilt 
	arm.rotation_degrees.x = -10

	_update_movement_sound()                   #calling audio func


func _handle_movement(delta):
	var dir = Input.get_axis("ui_down", "ui_up")
	translate(Vector3(0, 0, -dir) * move_speed * delta)

	var a_dir = Input.get_axis("ui_right", "ui_left")
	rotate_object_local(Vector3.UP, a_dir * turn_speed * delta)


func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()

	result.y = normal
	result.x = normal.cross(transform.basis.z).normalized()
	result.z = result.x.cross(normal).normalized()

	return result
	
	
func _update_movement_sound():
	var velocity = global_position - last_position
	var speed = velocity.length()

	if speed > 0.01:
		if not move_sound.playing:
			move_sound.pitch_scale = randf_range(1.0, 1.5)
			move_sound.play()
	else:
		if move_sound.playing:
			move_sound.stop()

	last_position = global_position
