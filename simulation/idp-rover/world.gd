extends Node3D

@export var rover: RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@onready var pivot: Node3D = $rover/pivot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rot := Input.get_axis("camera_left","camera_right") * delta
	pivot.rotate_y(rot)
