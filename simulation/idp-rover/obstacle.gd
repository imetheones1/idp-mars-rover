extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$StaticBody3D.rotation.y = randf()*2*PI


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
