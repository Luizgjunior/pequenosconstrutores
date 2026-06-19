extends Node3D


const BLOCK_SIZE := 1.0
const GROUND_TOP_Y := 0.2
const MAX_BUILD_DISTANCE := 18.0
const BUILD_LIMIT := 16.0

@onready var placed_blocks_root: Node3D = $PlacedBlocks

var block_mesh := BoxMesh.new()
var block_shape := BoxShape3D.new()
var block_material := StandardMaterial3D.new()
var player: CharacterBody3D
var camera: Camera3D


func _ready() -> void:
	player = get_node_or_null("../Player") as CharacterBody3D
	if player != null:
		camera = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D

	block_mesh.size = Vector3.ONE * BLOCK_SIZE
	block_shape.size = Vector3.ONE * BLOCK_SIZE
	block_material.albedo_color = Color(0.45, 0.27, 0.12, 1)
	block_material.roughness = 0.9


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


func _raycast_from_camera() -> Dictionary:
	if camera == null:
		return {}

	var viewport_size := get_viewport().get_visible_rect().size
	var screen_center := viewport_size * 0.5
	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_end := ray_origin + camera.project_ray_normal(screen_center) * MAX_BUILD_DISTANCE

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	if player != null:
		query.exclude = [player.get_rid()]

	return get_world_3d().direct_space_state.intersect_ray(query)


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
