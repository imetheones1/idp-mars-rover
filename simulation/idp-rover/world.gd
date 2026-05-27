extends Node3D

@export var rover: RigidBody3D

@onready var target_indicator: Node3D = $target_indicator
@onready var target_indicator_2: Node3D = $target_indicator_2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.created_heightmap:
		$StaticBody3D.update_terrain(Globals.created_heightmap_image)
		Globals.created_heightmap = false

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
