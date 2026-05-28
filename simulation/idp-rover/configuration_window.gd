extends Window

@onready var info_window: Window = $"../InfoWindow"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$flatness_weight_slider.value = Globals.pathfinding_flatness_weight
	$lateral_weight_slider.value = Globals.pathfinding_lateral_weight
	$rover_speed_slider.value = Globals.rover_pathing_speed 
	$flatness_weight_slider/Label.text = "Pathfinding flatness weight: %f" % Globals.pathfinding_flatness_weight
	$lateral_weight_slider/Label.text = "Pathfinding lateral weight: %f" % Globals.pathfinding_lateral_weight
	$rover_speed_slider/Label.text = "Rover speed when pathing: %f" % Globals.rover_pathing_speed
	info_window.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_flatness_weight_slider_value_changed(value: float) -> void:
	Globals.pathfinding_flatness_weight = value
	$flatness_weight_slider/Label.text = "Pathfinding flatness weight: %f" % value

func _on_lateral_weight_slider_value_changed(value: float) -> void:
	Globals.pathfinding_lateral_weight = value
	$lateral_weight_slider/Label.text = "Pathfinding lateral weight: %f" % value


func _on_rover_speed_slider_value_changed(value: float) -> void:
	Globals.rover_pathing_speed = value 
	$rover_speed_slider/Label.text = "Rover speed when pathing: %f" % value


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://terrain_draw.tscn")


func _on_info_window_close_requested() -> void:
	info_window.visible = false


func _on_info_button_pressed() -> void:
	info_window.visible = true
