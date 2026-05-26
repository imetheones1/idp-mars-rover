extends Node3D

@onready var target_cast: RayCast3D = $target_cast
@onready var target_indicator: Sprite3D = $target_indicator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_target():
	target_cast.force_update_transform()
	target_cast.force_raycast_update()
	if target_cast.is_colliding():
		target_indicator.global_position = target_cast.get_collision_point() + Vector3(0,10,0)
	else:
		target_indicator.top_level = false
		target_indicator.position = Vector3(0,10,0)
