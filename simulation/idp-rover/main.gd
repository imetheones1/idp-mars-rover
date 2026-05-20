extends Node2D

@onready var main_label: Label = $CanvasLayer/main_label
@onready var rover:RigidBody3D = $"3d/SubViewportContainer/SubViewport/world".rover

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	main_label.text = "fps: %f\n" % Engine.get_frames_per_second()
	main_label.text+= "position: (%.2f, %.2f, %.2f)\n" % [rover.global_position.x,rover.global_position.y,rover.global_position.z]
	main_label.text+= "vertex count: %d\n" % len(rover.terrain_points)
	main_label.text+= "new vertices: %d\n" % rover.new_point_count
	main_label.text+= "invalid vertices: %d\n" % rover.invalid_point_count
