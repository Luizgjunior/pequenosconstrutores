extends CharacterBody3D


const CHARACTER_MODEL_PATHS := {
	"boy_builder": "res://assets/models/characters/boy_builder.glb",
	"girl_builder": "res://assets/models/characters/girl_builder.glb",
}
const TARGET_MODEL_HEIGHT := 1.7

@export var move_speed := 5.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025
@export var camera_distance := 7.8
@export var camera_pitch_degrees := 45.0
@export var min_camera_pitch_degrees := 8.0
@export var max_camera_pitch_degrees := 82.0
@export var camera_pitch_sensitivity := 180.0

@onready var model_root: Node3D = $VisualRoot/ModelRoot
@onready var fallback_visual: Node3D = $VisualRoot/ModelRoot/FallbackVisual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_is_captured := true
var raw_movement_input := Vector2.ZERO
var camera_pitch := 45.0
var loaded_character_model: Node3D


func _ready() -> void:
	_ensure_default_input_actions()
	load_character_model(_get_selected_character_id())
	camera_pitch = camera_pitch_degrees
	_frame_camera_on_player()
	_capture_mouse()
	print("Player carregado: WASD move, Espaco pula, ESC alterna o mouse.")


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


func load_character_model(character_id: String) -> void:
	_clear_loaded_character_model()

	var current_model_root := _get_model_root()
	var current_fallback_visual := _get_fallback_visual()
	if current_model_root == null or current_fallback_visual == null:
		push_warning("Player sem ModelRoot ou FallbackVisual. Visual do personagem nao foi carregado.")
		return

	var normalized_id := character_id if CHARACTER_MODEL_PATHS.has(character_id) else "boy_builder"
	var model_path: String = CHARACTER_MODEL_PATHS[normalized_id]

	if ResourceLoader.exists(model_path):
		var packed_scene := load(model_path) as PackedScene
		if packed_scene != null:
			loaded_character_model = packed_scene.instantiate() as Node3D
			if loaded_character_model != null:
				loaded_character_model.name = "LoadedCharacterModel"
				current_model_root.add_child(loaded_character_model)
				current_fallback_visual.visible = false
				_fit_loaded_model_to_player(loaded_character_model)
				print("Modelo 3D do personagem carregado: ", model_path)
				return

	current_fallback_visual.visible = true
	_apply_fallback_style(normalized_id)
	print("Aviso: modelo 3D nao encontrado em ", model_path, ". Usando placeholder simples.")


func _clear_loaded_character_model() -> void:
	if loaded_character_model != null and is_instance_valid(loaded_character_model):
		loaded_character_model.queue_free()
	loaded_character_model = null


func _get_model_root() -> Node3D:
	if model_root != null:
		return model_root
	return get_node_or_null("VisualRoot/ModelRoot") as Node3D


func _get_fallback_visual() -> Node3D:
	if fallback_visual != null:
		return fallback_visual
	return get_node_or_null("VisualRoot/ModelRoot/FallbackVisual") as Node3D


func _fit_loaded_model_to_player(model: Node3D) -> void:
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO
	model.scale = Vector3.ONE

	var bounds := _calculate_local_mesh_bounds(model)
	if bounds.size.y <= 0.01:
		return

	var scale_factor := TARGET_MODEL_HEIGHT / bounds.size.y
	model.scale = Vector3.ONE * scale_factor
	model.position.y = -bounds.position.y * scale_factor


func _calculate_local_mesh_bounds(root: Node3D) -> AABB:
	var has_bounds := false
	var bounds := AABB()

	for mesh_node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue

		var local_aabb := mesh_instance.get_aabb()
		local_aabb.position += mesh_instance.position

		if has_bounds:
			bounds = bounds.merge(local_aabb)
		else:
			bounds = local_aabb
			has_bounds = true

	return bounds


func _get_selected_character_id() -> String:
	if has_node("/root/GameState"):
		return get_node("/root/GameState").selected_character_id
	return "boy_builder"


func _apply_fallback_style(character_id: String) -> void:
	var style := _get_fallback_style(character_id)

	_set_material_color("FallbackBody", style.body)
	_set_material_color("FallbackHead", style.skin)
	_set_material_color("FallbackHair", style.hair)
	_set_material_color("FallbackLeftArm", style.skin)
	_set_material_color("FallbackRightArm", style.skin)
	_set_material_color("FallbackLeftLeg", style.body)
	_set_material_color("FallbackRightLeg", style.body)
	_set_material_color("FallbackBelt", style.leather)


func _get_fallback_style(character_id: String) -> Dictionary:
	var styles := {
		"boy_builder": {
			"body": Color(0.32, 0.45, 0.52, 1),
			"skin": Color(0.78, 0.58, 0.42, 1),
			"hair": Color(0.19, 0.11, 0.06, 1),
			"leather": Color(0.28, 0.16, 0.08, 1),
		},
		"girl_builder": {
			"body": Color(0.36, 0.50, 0.58, 1),
			"skin": Color(0.80, 0.60, 0.44, 1),
			"hair": Color(0.23, 0.13, 0.07, 1),
			"leather": Color(0.32, 0.18, 0.09, 1),
		},
	}

	return styles.get(character_id, styles.boy_builder)


func _set_material_color(node_name: String, color: Color) -> void:
	var current_fallback_visual := _get_fallback_visual()
	if current_fallback_visual == null:
		return

	var mesh_instance := current_fallback_visual.get_node_or_null(node_name) as MeshInstance3D
	if mesh_instance == null:
		return

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_instance.material_override = material


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

	return input_vector


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
