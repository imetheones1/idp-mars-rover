extends Window

@export var target_one: Vector2
@export var target_two: Vector2
@export var rover_node: Node3D
var rover: Vector2

@export var padding: float = 1.15
@export var smoothing_speed: float = 5.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var terrain_cast: RayCast3D = $terrain_cast

@onready var obstacles: Node3D = $obstacles
const OBSTACLE = preload("uid://b7kh7fx0nc4id")

func _ready() -> void:
	camera_3d.rotation_degrees = Vector3(-90, 0, 0)
	camera_3d.position = Vector3(0, 50, 0)

func _process(delta: float) -> void:
	rover = Vector2(rover_node.global_position.x, rover_node.global_position.z)

	var target_diff := target_two - target_one
	
	var target_angle := -target_diff.angle() + deg_to_rad(45.0)
	
	camera_pivot.rotation.y = rotate_toward(camera_pivot.rotation.y, target_angle, smoothing_speed * delta)
	
	var cam_basis := Basis(Vector3.UP, camera_pivot.rotation.y)
	var cam_basis_inv := cam_basis.inverse()

	var to_local_cam := func(world_pos_2d: Vector2) -> Vector2:
		var cur_world_3d := Vector3(world_pos_2d.x, 0, world_pos_2d.y)
		var local_3d := cam_basis_inv * cur_world_3d
		return Vector2(local_3d.x, local_3d.z)

	var local_points: Array[Vector2] = []
	local_points.append(to_local_cam.call(target_one))
	local_points.append(to_local_cam.call(target_two))
	local_points.append(to_local_cam.call(rover))
	
	if "points" in rover_node and rover_node.points != null:
		for pt3d:Vector3 in rover_node.points:
			var pt2d := Vector2(pt3d.x, pt3d.z)
			local_points.append(to_local_cam.call(pt2d))
			
	var min_pos := local_points[0]
	var max_pos := local_points[0]
	
	for i in range(1, local_points.size()):
		min_pos.x = min(min_pos.x, local_points[i].x)
		min_pos.y = min(min_pos.y, local_points[i].y)
		max_pos.x = max(max_pos.x, local_points[i].x)
		max_pos.y = max(max_pos.y, local_points[i].y)
		
	var center_local_2d := (min_pos + max_pos) / 2.0
	var extents := max_pos - min_pos

	var window_size := Vector2(size)
	var aspect_ratio := window_size.x / window_size.y
	
	var required_size_by_height := extents.y
	var required_size_by_width := extents.x / aspect_ratio
	
	var target_ortho_size: float = max(required_size_by_height, required_size_by_width) * padding
	target_ortho_size = max(target_ortho_size, 5.0) 

	var center_local_3d := Vector3(center_local_2d.x, 0, center_local_2d.y)
	var target_3d_center := cam_basis * center_local_3d

	camera_pivot.position = camera_pivot.position.lerp(target_3d_center, smoothing_speed * delta)
	camera_3d.size = lerp(camera_3d.size, target_ortho_size, smoothing_speed * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("update_terrain"):
			var mouse_pos := get_mouse_position()

			var ray_origin := camera_3d.project_ray_origin(mouse_pos)
			var ray_dir := camera_3d.project_ray_normal(mouse_pos)

			terrain_cast.global_position = ray_origin
			terrain_cast.target_position = ray_dir * 1000.0
			terrain_cast.force_raycast_update()

			if terrain_cast.is_colliding():
				var hit_pos := terrain_cast.get_collision_point()

				var obstacle := OBSTACLE.instantiate()
				obstacle.global_position = hit_pos

				obstacles.add_child(obstacle)
		elif event.is_action_pressed("follow_path"):
			var mouse_pos := get_mouse_position()

			var ray_origin := camera_3d.project_ray_origin(mouse_pos)
			var ray_dir := camera_3d.project_ray_normal(mouse_pos)

			terrain_cast.global_position = ray_origin
			terrain_cast.target_position = ray_dir * 1000.0
			terrain_cast.force_raycast_update()

			if terrain_cast.is_colliding():
				var hit_pos := terrain_cast.get_collision_point()
				rover_node.teleport_target = hit_pos + Vector3.UP
				rover_node.teleport =true
				rover_node.sleeping = false
