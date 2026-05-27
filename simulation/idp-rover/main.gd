extends Node2D

@onready var main_label: Label = $CanvasLayer/main_label
@onready var rover:RigidBody3D = $"3d/SubViewportContainer/SubViewport/world".rover
@onready var freecam_window: Window = $FreecamWindow
@onready var bird_window: Window = $BirdWindow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	main_label.text = "fps: %f\n" % Engine.get_frames_per_second()
	main_label.text+= "position: (%.2f, %.2f, %.2f)\n" % [rover.global_position.x,rover.global_position.y,rover.global_position.z]
	main_label.text+= "current path point: %d\n" % rover.cur_point
	main_label.text+= "distance to current path point: %f\n" % rover.distance_to_target
	main_label.text+= "vertex count: %d\n" % len(rover.terrain_points)
	main_label.text+= "new vertices: %d\n" % rover.new_point_count
	main_label.text+= "invalid vertices: %d\n" % rover.invalid_point_count
	if !rover.has_path:
		main_label.text+= "ERROR: Rover cannot find path. \nPlease manually route to target or attempt to regenerate."
		
	bird_window.target_one = rover.target_one
	bird_window.target_two = rover.target_two
	bird_window.rover_node = rover

func _on_freecam_window_close_requested() -> void:
	get_tree().quit()
func _on_configuration_window_close_requested() -> void:
	get_tree().quit()
func _on_bird_window_close_requested() -> void:
	get_tree().quit()
