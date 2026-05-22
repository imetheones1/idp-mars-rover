extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
