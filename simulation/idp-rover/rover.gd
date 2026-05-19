extends RigidBody3D

@onready var wheels: Node3D = $wheels

func _physics_process(delta: float) -> void:
	var flip := Input.is_action_just_pressed("ui_accept")
	for wheel: Wheel in wheels.get_children():
		var force = wheel.calculate_force()
		if force != Vector3.ZERO:
			apply_force(force, wheel.global_position - global_position)
		if flip:
			apply_force(global_basis.y * 10 * sign(wheel.position.x), wheel.global_position - global_position)
	if flip:
		apply_force(Vector3.UP * 300,Vector3.ZERO)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var cur_speed = Input.get_axis("ui_down","ui_up") * 10
	for wheel: Wheel in wheels.get_children():
		wheel.cur_speed = cur_speed
	var cur_dir = Input.get_axis("ui_right","ui_left") * 60
	$wheels/fl.rotation_degrees.y = cur_dir
	$wheels/fr.rotation_degrees.y = cur_dir
