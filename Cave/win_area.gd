extends Area3D

@export var camera: Camera3D     # Player camera
@export var win_label: Label      # UI/BigWinLabel

var _won := false

func _ready() -> void:
	if win_label:
		win_label.visible = false     # hidden at start

	monitoring = false               # disable until cave is generated
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _won:
		return

	# Only react to the player
	if body.name != "Player":
		return

	_won = true

	if win_label:
		win_label.visible = true

	if camera:
		var tween := create_tween()
		var start_pos: Vector3 = camera.global_position
		var end_pos: Vector3 = start_pos + Vector3(0, 3, -6)
		tween.tween_property(camera, "global_position", end_pos, 2.0)
