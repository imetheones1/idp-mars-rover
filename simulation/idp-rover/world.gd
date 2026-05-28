extends Node3D

@export var rover: RigidBody3D

@onready var target_indicator: Node3D = $target_indicator
@onready var target_indicator_2: Node3D = $target_indicator_2

@onready var floor_checker: RayCast3D = $floor_checker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.created_heightmap:
		$StaticBody3D.update_terrain(Globals.created_heightmap_image)
		Globals.created_heightmap = false

func generate_random_rover_points():
	rover.reset_rover()
	
	var new_target_one := Vector2(randf_range(-100,100),randf_range(-100,100))
	rover.target_one = new_target_one
	floor_checker.global_position.x = new_target_one.x
	floor_checker.global_position.z = new_target_one.y
	floor_checker.force_update_transform()
	floor_checker.force_raycast_update()
	if not floor_checker.is_colliding():
		push_error("floor failed to find at %s" % new_target_one)
		return
	rover.teleport_target = floor_checker.get_collision_point() + Vector3.UP
	rover.teleport = true
	rover.sleeping = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await rover.updated_points
	await rover.updated_points
	
	var new_target_two := Vector2(randf_range(-100,100),randf_range(-100,100))
	rover.target_two = new_target_two
	floor_checker.global_position.x = new_target_two.x
	floor_checker.global_position.z = new_target_two.y
	floor_checker.force_update_transform()
	floor_checker.force_raycast_update()
	if not floor_checker.is_colliding():
		push_error("floor failed to find at %s" % new_target_two)
		return
	rover.teleport_target = floor_checker.get_collision_point() + Vector3.UP
	rover.teleport= true
	rover.sleeping = false
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await rover.updated_points
	await rover.updated_points
	
	rover.update_target()
	rover.write_terrain_to_file()
	rover.cur_state = rover.STATE.FOLLOWING

@onready var pivot: Node3D = $rover/pivot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if DisplayServer.window_is_focused():
		var rot := Input.get_axis("camera_left","camera_right") * delta
		pivot.rotate_y(rot)


func _on_rover_target_one_change(newval: Vector2) -> void:
	target_indicator.global_position = Vector3(newval.x,0,newval.y)
	target_indicator.update_target()
	print("set target 1 position to %s" % target_indicator.global_position)


func _on_rover_target_two_change(newval: Vector2) -> void:
	target_indicator_2.global_position = Vector3(newval.x,0,newval.y)
	target_indicator_2.update_target()
	print("set target 2 position to %s" % target_indicator.global_position)
