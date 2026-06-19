extends Node3D


const BLOCK_SIZE := 1.0
const GROUND_TOP_Y := 0.2
const MAX_BUILD_DISTANCE := 18.0
const BUILD_LIMIT := 16.0
const AIM_SPEED := 1.0
const AIM_MARGIN := 18.0
const SAVE_PATH := "user://placed_blocks.json"
const MISSION_WOOD_TARGET := 6
const MISSION_AREA_LIMIT := 6.0
const ARK_BASE_TARGET := 12
const ARK_BASE_LIMIT_X := 4.0
const ARK_BASE_LIMIT_Z := 1.5

@onready var placed_blocks_root: Node3D = $PlacedBlocks
@onready var crosshair: Control = get_node_or_null("../AimLayer/Crosshair") as Control
@onready var selected_block_label: Label = get_node_or_null("../HudLayer/Panel/VBox/SelectedBlockLabel") as Label
@onready var mode_label: Label = get_node_or_null("../HudLayer/Panel/VBox/ModeLabel") as Label
@onready var tutorial_label: Label = get_node_or_null("../HudLayer/Panel/VBox/TutorialLabel") as Label
@onready var ark_mission_label: Label = get_node_or_null("../HudLayer/Panel/VBox/ArkMissionLabel") as Label
@onready var wood_slot_label: Label = get_node_or_null("../HudLayer/Panel/VBox/BlockBar/WoodSlot") as Label
@onready var stone_slot_label: Label = get_node_or_null("../HudLayer/Panel/VBox/BlockBar/StoneSlot") as Label
@onready var sand_slot_label: Label = get_node_or_null("../HudLayer/Panel/VBox/BlockBar/SandSlot") as Label
@onready var save_button: Button = get_node_or_null("../HudLayer/Panel/VBox/Buttons/SaveButton") as Button
@onready var clear_button: Button = get_node_or_null("../HudLayer/Panel/VBox/Buttons/ClearButton") as Button
@onready var menu_button: Button = get_node_or_null("../HudLayer/Panel/VBox/Buttons/MenuButton") as Button

var block_mesh := BoxMesh.new()
var block_shape := BoxShape3D.new()
var preview_material := StandardMaterial3D.new()
var blocked_preview_material := StandardMaterial3D.new()
var arrow_material := StandardMaterial3D.new()
var preview_block: MeshInstance3D
var preview_arrow: MeshInstance3D
var player: CharacterBody3D
var camera: Camera3D
var aim_screen_position := Vector2.ZERO
var selected_block_type := "wood"
var build_mode_enabled := true
var tutorial_completed := false
var ark_mission_completed := false
var block_materials := {}


func _ready() -> void:
	player = get_node_or_null("../Player") as CharacterBody3D
	if player != null:
		camera = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
		if player.has_method("set_camera_control_enabled"):
			player.set_camera_control_enabled(false)

	aim_screen_position = get_viewport().get_visible_rect().size * 0.5
	block_mesh.size = Vector3.ONE * BLOCK_SIZE
	block_shape.size = Vector3.ONE * BLOCK_SIZE
	_setup_block_materials()
	_setup_preview()
	_setup_buttons()
	_update_crosshair_position()
	_load_blocks()
	_update_hud()


func _process(_delta: float) -> void:
	_update_crosshair_position()
	_update_preview()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key_input(event)
	elif build_mode_enabled and event is InputEventMouseMotion:
		_move_aim(event.relative * AIM_SPEED)


func _unhandled_input(event: InputEvent) -> void:
	if not build_mode_enabled:
		return

	if event.is_action_pressed("place_block"):
		place_block_from_camera()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("remove_block"):
		remove_block_from_camera()
		get_viewport().set_input_as_handled()


func place_block_from_camera() -> void:
	var hit := _raycast_from_camera()
	if hit.is_empty():
		return

	var block_position := _get_place_position(hit)
	if not _can_place_at(block_position):
		return

	_create_block(block_position, selected_block_type)
	_save_blocks()
	_update_hud()


func remove_block_from_camera() -> void:
	var hit := _raycast_from_camera()
	if hit.is_empty():
		return

	var collider := hit.get("collider") as Node
	if collider != null and collider.is_in_group("placed_blocks"):
		collider.queue_free()
		await get_tree().process_frame
		_save_blocks()
		_update_hud()


func _setup_buttons() -> void:
	if save_button != null:
		save_button.pressed.connect(_on_save_pressed)
	if clear_button != null:
		clear_button.pressed.connect(_on_clear_pressed)
	if menu_button != null:
		menu_button.pressed.connect(_on_menu_pressed)


func _on_save_pressed() -> void:
	_save_blocks()
	print("Construcao salva.")


func _on_clear_pressed() -> void:
	_clear_blocks()
	await get_tree().process_frame
	tutorial_completed = false
	ark_mission_completed = false
	_save_blocks()
	_update_hud()


func _on_menu_pressed() -> void:
	_save_blocks()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _handle_key_input(event: InputEventKey) -> void:
	var key := event.physical_keycode
	if key == KEY_NONE:
		key = event.keycode

	match key:
		KEY_1:
			_select_block("wood")
		KEY_2:
			_select_block("stone")
		KEY_3:
			_select_block("sand")
		KEY_TAB:
			_toggle_build_mode()


func _select_block(block_type: String) -> void:
	if not block_materials.has(block_type):
		return

	selected_block_type = block_type
	_update_hud()


func _toggle_build_mode() -> void:
	build_mode_enabled = not build_mode_enabled
	if player != null and player.has_method("set_camera_control_enabled"):
		player.set_camera_control_enabled(not build_mode_enabled)
	if crosshair != null:
		crosshair.visible = build_mode_enabled
	_update_hud()


func _setup_block_materials() -> void:
	block_materials = {
		"wood": _create_material(Color(0.45, 0.27, 0.12, 1)),
		"stone": _create_material(Color(0.42, 0.40, 0.36, 1)),
		"sand": _create_material(Color(0.76, 0.62, 0.39, 1)),
	}


func _create_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _create_block(block_position: Vector3, block_type: String) -> StaticBody3D:
	var block := StaticBody3D.new()
	block.name = "%sBlock" % block_type.capitalize()
	block.position = block_position
	block.set_meta("block_type", block_type)
	block.add_to_group("placed_blocks")

	var collision := CollisionShape3D.new()
	collision.shape = block_shape
	block.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = block_mesh
	mesh_instance.material_override = block_materials.get(block_type, block_materials.wood)
	block.add_child(mesh_instance)

	placed_blocks_root.add_child(block)
	return block


func _clear_blocks() -> void:
	for block in placed_blocks_root.get_children():
		block.queue_free()


func _setup_preview() -> void:
	preview_material.albedo_color = Color(0.25, 0.9, 0.38, 0.42)
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material.roughness = 0.8

	blocked_preview_material.albedo_color = Color(0.9, 0.18, 0.12, 0.35)
	blocked_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blocked_preview_material.roughness = 0.8

	arrow_material.albedo_color = Color(0.98, 0.86, 0.36, 1)
	arrow_material.roughness = 0.7

	preview_block = MeshInstance3D.new()
	preview_block.name = "BuildPreviewBlock"
	preview_block.mesh = block_mesh
	preview_block.material_override = preview_material
	preview_block.visible = false
	add_child(preview_block)

	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.18
	arrow_mesh.height = 0.42

	preview_arrow = MeshInstance3D.new()
	preview_arrow.name = "BuildPreviewArrow"
	preview_arrow.mesh = arrow_mesh
	preview_arrow.material_override = arrow_material
	preview_arrow.visible = false
	add_child(preview_arrow)


func _update_preview() -> void:
	if preview_block == null or preview_arrow == null:
		return

	if not build_mode_enabled:
		preview_block.visible = false
		preview_arrow.visible = false
		return

	var hit := _raycast_from_camera()
	if hit.is_empty():
		preview_block.visible = false
		preview_arrow.visible = false
		return

	var block_position := _get_place_position(hit)
	var can_place := _can_place_at(block_position)
	preview_block.global_position = block_position
	preview_block.material_override = preview_material if can_place else blocked_preview_material
	preview_block.visible = true

	preview_arrow.global_position = block_position + Vector3(0.0, 0.95, 0.0)
	preview_arrow.visible = can_place


func _raycast_from_camera() -> Dictionary:
	if camera == null:
		return {}

	var ray_origin := camera.project_ray_origin(aim_screen_position)
	var ray_end := ray_origin + camera.project_ray_normal(aim_screen_position) * MAX_BUILD_DISTANCE

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	if player != null:
		query.exclude = [player.get_rid()]

	return get_world_3d().direct_space_state.intersect_ray(query)


func _move_aim(delta: Vector2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	aim_screen_position += delta
	aim_screen_position.x = clampf(aim_screen_position.x, AIM_MARGIN, viewport_size.x - AIM_MARGIN)
	aim_screen_position.y = clampf(aim_screen_position.y, AIM_MARGIN, viewport_size.y - AIM_MARGIN)


func _update_crosshair_position() -> void:
	if crosshair == null:
		return

	crosshair.global_position = aim_screen_position - crosshair.size * 0.5


func _update_hud() -> void:
	if selected_block_label != null:
		selected_block_label.text = "Bloco: %s  (1 Madeira, 2 Pedra, 3 Areia)" % _get_block_display_name(selected_block_type)
	if mode_label != null:
		mode_label.text = "Modo: %s  (Tab alterna)" % ("Construcao" if build_mode_enabled else "Camera")
	if tutorial_label != null:
		var tutorial_wood_count := _count_tutorial_wood_blocks()
		if tutorial_wood_count >= MISSION_WOOD_TARGET:
			tutorial_completed = true

		tutorial_label.visible = not tutorial_completed
		if not tutorial_completed:
			tutorial_label.text = "Tutorial: coloque %d/%d blocos de madeira na area central" % [tutorial_wood_count, MISSION_WOOD_TARGET]
		else:
			tutorial_label.text = ""
	if ark_mission_label != null:
		var ark_wood_count := _count_ark_base_wood_blocks()
		if ark_wood_count >= ARK_BASE_TARGET:
			ark_mission_completed = true

		ark_mission_label.visible = tutorial_completed
		if ark_mission_completed:
			ark_mission_label.text = "Arca de Noe: base iniciada! Excelente construtor."
		else:
			ark_mission_label.text = "Arca de Noe: construa a base %d/%d com madeira" % [ark_wood_count, ARK_BASE_TARGET]
	_update_block_bar()


func _update_block_bar() -> void:
	_set_slot_style(wood_slot_label, "wood")
	_set_slot_style(stone_slot_label, "stone")
	_set_slot_style(sand_slot_label, "sand")


func _set_slot_style(label: Label, block_type: String) -> void:
	if label == null:
		return

	var selected := block_type == selected_block_type
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 1) if selected else Color(0.88, 0.84, 0.76, 1))


func _get_block_display_name(block_type: String) -> String:
	match block_type:
		"wood":
			return "Madeira"
		"stone":
			return "Pedra"
		"sand":
			return "Areia"
		_:
			return block_type


func _count_tutorial_wood_blocks() -> int:
	var total := 0
	for block in placed_blocks_root.get_children():
		if not block is Node3D:
			continue
		if block.get_meta("block_type", "") != "wood":
			continue
		if abs(block.position.x) <= MISSION_AREA_LIMIT and abs(block.position.z) <= MISSION_AREA_LIMIT:
			total += 1
	return total


func _count_ark_base_wood_blocks() -> int:
	var total := 0
	for block in placed_blocks_root.get_children():
		if not block is Node3D:
			continue
		if block.get_meta("block_type", "") != "wood":
			continue
		if abs(block.position.x) <= ARK_BASE_LIMIT_X and abs(block.position.z) <= ARK_BASE_LIMIT_Z:
			total += 1
	return total


func _get_place_position(hit: Dictionary) -> Vector3:
	var hit_position := hit["position"] as Vector3
	var hit_normal := hit["normal"] as Vector3
	var collider := hit["collider"] as Node
	var target_position := hit_position

	if collider != null and collider.is_in_group("placed_blocks") and collider is Node3D:
		target_position = (collider as Node3D).global_position + hit_normal * BLOCK_SIZE

	return _snap_to_block_grid(target_position)


func _snap_to_block_grid(world_position: Vector3) -> Vector3:
	var first_block_center_y := GROUND_TOP_Y + BLOCK_SIZE * 0.5
	return Vector3(
		round(world_position.x / BLOCK_SIZE) * BLOCK_SIZE,
		first_block_center_y + round((world_position.y - first_block_center_y) / BLOCK_SIZE) * BLOCK_SIZE,
		round(world_position.z / BLOCK_SIZE) * BLOCK_SIZE
	)


func _can_place_at(block_position: Vector3) -> bool:
	if abs(block_position.x) > BUILD_LIMIT or abs(block_position.z) > BUILD_LIMIT:
		return false

	for block in placed_blocks_root.get_children():
		if block is Node3D and block.position.distance_squared_to(block_position) < 0.01:
			return false

	if player != null:
		var flat_distance := Vector2(player.global_position.x, player.global_position.z).distance_to(
			Vector2(block_position.x, block_position.z)
		)
		if flat_distance < 1.1 and block_position.y < 1.3:
			return false

	return true


func _save_blocks() -> void:
	var blocks := []
	for block in placed_blocks_root.get_children():
		if not block is Node3D:
			continue
		blocks.append({
			"type": block.get_meta("block_type", "wood"),
			"position": [block.position.x, block.position.y, block.position.z],
		})

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(blocks))


func _load_blocks() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		return

	for block_data in parsed:
		if not block_data is Dictionary:
			continue
		var position_data: Array = block_data.get("position", [])
		if position_data.size() != 3:
			continue
		var block_position := Vector3(position_data[0], position_data[1], position_data[2])
		var block_type: String = block_data.get("type", "wood")
		if block_materials.has(block_type):
			_create_block(block_position, block_type)
