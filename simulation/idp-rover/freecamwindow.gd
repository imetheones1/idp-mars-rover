extends Window

var rover:RigidBody3D
@onready var free_look_camera: FreeLookCamera = $FreeLookCamera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rover = $"../3d/SubViewportContainer/SubViewport/world".rover

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_accept"):
			rover.teleport_target = free_look_camera.global_position
			rover.teleport = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
