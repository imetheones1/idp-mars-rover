extends Window

var rover:RigidBody3D
@onready var free_look_camera: FreeLookCamera = $FreeLookCamera
@onready var extra: Node3D = $extra
const OBSTACLE = preload("uid://b7kh7fx0nc4id")
@onready var ray_cast_3d: RayCast3D = $FreeLookCamera/RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rover = $"../3d/SubViewportContainer/SubViewport/world".rover

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_accept"):
			rover.teleport_target = free_look_camera.global_position
			rover.teleport = true
		elif event.is_action_pressed("update_terrain"):
			if ray_cast_3d.is_colliding():
				var cur:Node3D = OBSTACLE.instantiate()
				extra.add_child(cur)
				cur.global_position = ray_cast_3d.get_collision_point()
				cur.global_position += Vector3.UP

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
