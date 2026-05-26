extends Window

@export var target_one: Vector2
@export var target_two: Vector2
@export var rover: Vector2

@export var padding: float = 1.15
@export var smoothing_speed: float = 5.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D


func _ready() -> void:
	camera_3d.rotation_degrees = Vector3(-90, 0, 0)
	camera_3d.position = Vector3(0, 50, 0)


func _process(delta: float) -> void:
	var min_pos := Vector2(min(target_one.x, target_two.x), min(target_one.y, target_two.y))
	var max_pos := Vector2(max(target_one.x, target_two.x), max(target_one.y, target_two.y))
	
	min_pos.x = min(min_pos.x, rover.x)
	min_pos.y = min(min_pos.y, rover.y)
	max_pos.x = max(max_pos.x, rover.x)
	max_pos.y = max(max_pos.y, rover.y)
	
	var center_2d := (min_pos + max_pos) / 2.0
	var extents := max_pos - min_pos

	var window_size := Vector2(size)
	var aspect_ratio := window_size.x / window_size.y
	
	var required_size_by_height := extents.y
	var required_size_by_width := extents.x / aspect_ratio
	
	var target_ortho_size:float = max(required_size_by_height, required_size_by_width) * padding
	
	target_ortho_size = max(target_ortho_size, 5.0) 

	var target_3d_center := Vector3(center_2d.x, 0, center_2d.y)
	
	camera_pivot.position = camera_pivot.position.lerp(target_3d_center, smoothing_speed * delta)
	camera_3d.size = lerp(camera_3d.size, target_ortho_size, smoothing_speed * delta)
