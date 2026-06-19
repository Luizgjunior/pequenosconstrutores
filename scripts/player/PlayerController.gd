extends CharacterBody3D


@export var move_speed := 5.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025
@export var camera_distance := 7.0
@export var camera_pitch_degrees := 45.0
@export var min_camera_pitch_degrees := 18.0
@export var max_camera_pitch_degrees := 78.0
@export var camera_pitch_sensitivity := 180.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var left_arm_pivot: Node3D = $VisualRoot/LeftArmPivot
@onready var right_arm_pivot: Node3D = $VisualRoot/RightArmPivot
@onready var left_leg_pivot: Node3D = $VisualRoot/LeftLegPivot
@onready var right_leg_pivot: Node3D = $VisualRoot/RightLegPivot

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_captured := true
var walk_time := 0.0
var current_camera_pitch := 45.0


func _ready() -> void:
	current_camera_pitch = camera_pitch_degrees
	_update_camera_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		mouse_captured = not mouse_captured
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)
		get_viewport().set_input_as_handled()
		return

	if mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		current_camera_pitch = clamp(
			current_camera_pitch + event.relative.y * mouse_sensitivity * camera_pitch_sensitivity,
			min_camera_pitch_degrees,
			max_camera_pitch_degrees
		)
		_update_camera_position()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction := (right * input_vector.x + forward * -input_vector.y).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()
	_animate_blocky_walk(delta)


func _update_camera_position() -> void:
	current_camera_pitch = clamp(current_camera_pitch, min_camera_pitch_degrees, max_camera_pitch_degrees)
	var pitch := deg_to_rad(current_camera_pitch)
	camera_pivot.position = Vector3(0, 1.6, 0)
	camera.position = Vector3(0, sin(pitch) * camera_distance, cos(pitch) * camera_distance)
	camera.look_at(global_position + Vector3(0, 1.0, 0), Vector3.UP)


func _animate_blocky_walk(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		walk_time += delta * 8.0
		var swing := sin(walk_time) * 0.45
		left_arm_pivot.rotation.x = swing
		right_arm_pivot.rotation.x = -swing
		left_leg_pivot.rotation.x = -swing
		right_leg_pivot.rotation.x = swing
	else:
		left_arm_pivot.rotation = left_arm_pivot.rotation.lerp(Vector3.ZERO, delta * 8.0)
		right_arm_pivot.rotation = right_arm_pivot.rotation.lerp(Vector3.ZERO, delta * 8.0)
		left_leg_pivot.rotation = left_leg_pivot.rotation.lerp(Vector3.ZERO, delta * 8.0)
		right_leg_pivot.rotation = right_leg_pivot.rotation.lerp(Vector3.ZERO, delta * 8.0)
