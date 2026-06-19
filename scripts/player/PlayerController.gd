extends CharacterBody3D


@export var move_speed := 5.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025
@export var camera_distance := 7.8
@export var camera_pitch_degrees := 45.0
@export var min_camera_pitch_degrees := 8.0
@export var max_camera_pitch_degrees := 82.0
@export var camera_pitch_sensitivity := 180.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var body_mesh: MeshInstance3D = $VisualRoot/Body
@onready var head_mesh: MeshInstance3D = $VisualRoot/Head
@onready var hair_mesh: MeshInstance3D = $VisualRoot/Hair
@onready var left_arm_pivot: Node3D = $VisualRoot/LeftArmPivot
@onready var right_arm_pivot: Node3D = $VisualRoot/RightArmPivot
@onready var left_leg_pivot: Node3D = $VisualRoot/LeftLegPivot
@onready var right_leg_pivot: Node3D = $VisualRoot/RightLegPivot
@onready var left_arm_mesh: MeshInstance3D = $VisualRoot/LeftArmPivot/LeftArm
@onready var right_arm_mesh: MeshInstance3D = $VisualRoot/RightArmPivot/RightArm
@onready var left_leg_mesh: MeshInstance3D = $VisualRoot/LeftLegPivot/LeftLeg
@onready var right_leg_mesh: MeshInstance3D = $VisualRoot/RightLegPivot/RightLeg
@onready var accessory_root: Node3D = $VisualRoot/Accessories

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_is_captured := true
var raw_movement_input := Vector2.ZERO
var walk_time := 0.0
var camera_pitch := 45.0
var default_left_arm_rotation := Vector3.ZERO
var default_right_arm_rotation := Vector3.ZERO
var default_left_leg_rotation := Vector3.ZERO
var default_right_leg_rotation := Vector3.ZERO


func _ready() -> void:
	_ensure_default_input_actions()
	_store_default_limb_pose()
	_apply_selected_character()
	camera_pitch = camera_pitch_degrees
	_frame_camera_on_player()
	_capture_mouse()
	print("Player carregado: WASD move, Espaço pula, ESC alterna o mouse.")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		_update_raw_movement_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_mouse_capture()
		get_viewport().set_input_as_handled()
		return

	if mouse_is_captured and event is InputEventMouseMotion:
		_update_camera_rotation(event.relative)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_jump()
	_apply_movement()
	move_and_slide()
	_animate_walk(delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func _apply_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func _apply_movement() -> void:
	var input_vector := _get_movement_input()
	var direction := _get_camera_relative_direction(input_vector)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed


func _get_movement_input() -> Vector2:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	if input_vector == Vector2.ZERO:
		input_vector = raw_movement_input.normalized()

	if input_vector == Vector2.ZERO:
		input_vector = _get_keyboard_fallback_input()

	# print("Movimento detectado: ", input_vector)
	return input_vector


func _store_default_limb_pose() -> void:
	default_left_arm_rotation = left_arm_pivot.rotation
	default_right_arm_rotation = right_arm_pivot.rotation
	default_left_leg_rotation = left_leg_pivot.rotation
	default_right_leg_rotation = right_leg_pivot.rotation


func _animate_walk(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_walking := is_on_floor() and horizontal_speed > 0.1

	if is_walking:
		walk_time += delta * 9.0
		var swing := sin(walk_time) * 0.55
		left_arm_pivot.rotation.x = default_left_arm_rotation.x + swing
		right_arm_pivot.rotation.x = default_right_arm_rotation.x - swing
		left_leg_pivot.rotation.x = default_left_leg_rotation.x - swing * 0.75
		right_leg_pivot.rotation.x = default_right_leg_rotation.x + swing * 0.75
	else:
		left_arm_pivot.rotation = left_arm_pivot.rotation.lerp(default_left_arm_rotation, delta * 10.0)
		right_arm_pivot.rotation = right_arm_pivot.rotation.lerp(default_right_arm_rotation, delta * 10.0)
		left_leg_pivot.rotation = left_leg_pivot.rotation.lerp(default_left_leg_rotation, delta * 10.0)
		right_leg_pivot.rotation = right_leg_pivot.rotation.lerp(default_right_leg_rotation, delta * 10.0)


func _get_keyboard_fallback_input() -> Vector2:
	var fallback := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A):
		fallback.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D):
		fallback.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W):
		fallback.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S):
		fallback.y += 1.0

	return fallback.normalized()


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector == Vector2.ZERO:
		return Vector3.ZERO

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	return ((right * input_vector.x) + (forward * -input_vector.y)).normalized()


func _update_camera_rotation(mouse_delta: Vector2) -> void:
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	camera_pitch = clamp(
		camera_pitch + mouse_delta.y * mouse_sensitivity * camera_pitch_sensitivity,
		min_camera_pitch_degrees,
		max_camera_pitch_degrees
	)
	_frame_camera_on_player()


func _frame_camera_on_player() -> void:
	camera_pitch = clamp(camera_pitch, min_camera_pitch_degrees, max_camera_pitch_degrees)
	camera_pivot.position = Vector3(0.0, 1.8, 0.0)
	var pitch_radians := deg_to_rad(camera_pitch)
	camera.position = Vector3(
		0.0,
		sin(pitch_radians) * camera_distance,
		cos(pitch_radians) * camera_distance
	)
	camera.look_at(global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _toggle_mouse_capture() -> void:
	if mouse_is_captured:
		_release_mouse()
	else:
		_capture_mouse()


func _capture_mouse() -> void:
	mouse_is_captured = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _release_mouse() -> void:
	mouse_is_captured = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _update_raw_movement_input(event: InputEventKey) -> void:
	var key := event.physical_keycode
	if key == KEY_NONE:
		key = event.keycode

	var axis_value := 1.0 if event.pressed else 0.0

	match key:
		KEY_A:
			raw_movement_input.x = -axis_value
		KEY_D:
			raw_movement_input.x = axis_value
		KEY_W:
			raw_movement_input.y = -axis_value
		KEY_S:
			raw_movement_input.y = axis_value


func _ensure_default_input_actions() -> void:
	_ensure_key_action("move_forward", KEY_W)
	_ensure_key_action("move_backward", KEY_S)
	_ensure_key_action("move_left", KEY_A)
	_ensure_key_action("move_right", KEY_D)
	_ensure_key_action("jump", KEY_SPACE)
	_ensure_key_action("pause", KEY_ESCAPE)


func _ensure_key_action(action_name: StringName, physical_key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == physical_key:
			return

	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_key
	InputMap.action_add_event(action_name, key_event)


func _apply_selected_character() -> void:
	var selected_id := "boy_builder"
	if has_node("/root/GameState"):
		selected_id = get_node("/root/GameState").selected_character_id

	var style := _get_character_style(selected_id)
	_apply_material(body_mesh, style.body)
	_apply_material(left_leg_mesh, style.body)
	_apply_material(right_leg_mesh, style.body)
	_apply_material(head_mesh, style.skin)
	_apply_material(left_arm_mesh, style.skin)
	_apply_material(right_arm_mesh, style.skin)
	_apply_material(hair_mesh, style.hair)
	_set_accessories(style.accessories)


func _get_character_style(character_id: String) -> Dictionary:
	var styles := {
		"boy_builder": {
			"body": Color(0.23, 0.39, 0.50, 1),
			"skin": Color(0.78, 0.58, 0.42, 1),
			"hair": Color(0.22, 0.13, 0.07, 1),
			"accessories": ["belt"]
		},
		"girl_builder": {
			"body": Color(0.30, 0.46, 0.56, 1),
			"skin": Color(0.80, 0.60, 0.44, 1),
			"hair": Color(0.24, 0.14, 0.08, 1),
			"accessories": ["belt"]
		}
	}

	return styles.get(character_id, styles.boy_builder)


func _apply_material(mesh_instance: MeshInstance3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh_instance.material_override = material


func _set_accessories(active_accessories: Array) -> void:
	for accessory in accessory_root.get_children():
		accessory.visible = active_accessories.has(accessory.name.to_snake_case())
