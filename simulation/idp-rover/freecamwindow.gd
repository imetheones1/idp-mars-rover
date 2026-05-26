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
			if Input.is_key_pressed(KEY_SHIFT):
				free_look_camera.global_position = rover.global_position
			else:
				rover.teleport_target = free_look_camera.global_position
				rover.teleport = true
		elif event.is_action_pressed("update_terrain"):
			if ray_cast_3d.is_colliding():
				var collision_point := ray_cast_3d.get_collision_point()
				if Vector2(collision_point.x,collision_point.z).length_squared() <= 7*7:
					return
				var cur:Node3D = OBSTACLE.instantiate()
				extra.add_child(cur)
				cur.global_position = collision_point
				cur.global_position += Vector3.UP
		elif event.is_action_pressed("set_target_1"):
			if ray_cast_3d.is_colliding():
				var collision_point := ray_cast_3d.get_collision_point()
				rover.add_target_point(1,collision_point)
				rover.teleport_target = collision_point + Vector3(0,2,0)
				rover.teleport = true
		elif event.is_action_pressed("set_target_2"):
			if ray_cast_3d.is_colliding():
				var collision_point := ray_cast_3d.get_collision_point()
				rover.add_target_point(2,collision_point)
				rover.teleport_target = collision_point + Vector3(0,2,0)
				rover.teleport = true
		elif event.is_action_pressed("follow_path"):
			if ray_cast_3d.is_colliding():
				rover.teleport_target = ray_cast_3d.get_collision_point() + Vector3(0,2,0)
				rover.teleport = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
