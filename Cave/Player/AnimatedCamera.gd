class_name AnimatedCam
extends Camera3D



# Tutorial values for accel cam
@export
var SENSITIVITY = 0.50
const SMOOTHNESS = 15

var camera_input : Vector2
var rotation_velocity : Vector2

var minLookAngle = -75
var maxLookAngle = 75
var mouseDelta = Vector2()

@onready
var playerRef : CharacterBody3D = get_parent()

#@onready
#var camera_animations : AnimationPlayer = $CameraAnimations


func _ready():
	
	#playerRef = get_node(playerRef)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		camera_input = event.relative
	
func _physics_process(delta: float) -> void:
	#If mouse is exposed, don't do any of this.
	#Too wonky
	
	#if playerRef.dead:
		#return
	
	#We still want the player to be able to move, so these animations are fine
	#handleCameraAnimation()
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		return
	
	#If mouse is exposed, don't do any of this.
	#Too wonky
	handleCameraTurning(delta)

func handleCameraTurning(delta):

	rotation_velocity = rotation_velocity.lerp(camera_input * SENSITIVITY, delta * SMOOTHNESS)
	self.rotate_x(-deg_to_rad(rotation_velocity.y))
	# Rotate the player around the y
	playerRef.rotate_y(-deg_to_rad(rotation_velocity.x))
	self.rotation_degrees.x = clamp(self.rotation_degrees.x, -90, 90)
	camera_input = Vector2.ZERO
	
