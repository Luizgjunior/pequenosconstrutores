extends Node3D


const BLOCK_SIZE := 1.0
const GROUND_TOP_Y := 0.2
const MAX_BUILD_DISTANCE := 18.0
const BUILD_LIMIT := 16.0
const AIM_SPEED := 1.0
const AIM_MARGIN := 18.0

@onready var placed_blocks_root: Node3D = $PlacedBlocks
@onready var crosshair: Control = get_node_or_null("../AimLayer/Crosshair") as Control

var block_mesh := BoxMesh.new()
var block_shape := BoxShape3D.new()
var block_material := StandardMaterial3D.new()
var preview_material := StandardMaterial3D.new()
var blocked_preview_material := StandardMaterial3D.new()
var arrow_material := StandardMaterial3D.new()
var preview_block: MeshInstance3D
var preview_arrow: MeshInstance3D
var player: CharacterBody3D
var camera: Camera3D
var aim_screen_position := Vector2.ZERO


func _ready() -> void:
	player = get_node_or_null("../Player") as CharacterBody3D
	if player != null:
		camera = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D

	aim_screen_position = get_viewport().get_visible_rect().size * 0.5
	block_mesh.size = Vector3.ONE * BLOCK_SIZE
	block_shape.size = Vector3.ONE * BLOCK_SIZE
	block_material.albedo_color = Color(0.45, 0.27, 0.12, 1)
	block_material.roughness = 0.9
	_setup_preview()
	_update_crosshair_position()


func _process(_delta: float) -> void:
	_update_crosshair_position()
	_update_preview()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_move_aim(event.relative * AIM_SPEED)


func _unhandled_input(event: InputEvent) -> void:
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

	var block := StaticBody3D.new()
	block.name = "WoodBlock"
	block.position = block_position
	block.add_to_group("placed_blocks")

	var collision := CollisionShape3D.new()
	collision.shape = block_shape
	block.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = block_mesh
	mesh_instance.material_override = block_material
	block.add_child(mesh_instance)

	placed_blocks_root.add_child(block)


func remove_block_from_camera() -> void:
	var hit := _raycast_from_camera()
	if hit.is_empty():
		return

	var collider := hit.get("collider") as Node
	if collider != null and collider.is_in_group("placed_blocks"):
		collider.queue_free()


func _setup_preview() -> void:
	preview_material.albedo_color = Color(0.9, 0.72, 0.35, 0.42)
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
