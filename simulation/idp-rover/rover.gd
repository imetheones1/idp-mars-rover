extends RigidBody3D

@onready var wheels: Node3D = $wheels

func _physics_process(delta: float) -> void:
	for wheel: Wheel in wheels.get_children():
		var force = wheel.calculate_force()
		if force != Vector3.ZERO:
			apply_force(force, wheel.global_position - global_position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var cur_speed = Input.get_axis("ui_down","ui_up") * 10
	#for wheel: Wheel in wheels.get_children():
		#wheel.cur_speed = cur_speed
	$wheels/fl.cur_speed = cur_speed
	$wheels/fr.cur_speed = cur_speed
	var cur_dir = Input.get_axis("ui_right","ui_left") * 20
	$wheels/fl.rotation_degrees.y = cur_dir
	$wheels/fr.rotation_degrees.y = cur_dir
