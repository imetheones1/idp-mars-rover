extends RigidBody3D

@onready var wheels: Node3D = $wheels

func damp(a,b,lambda:float,dt:float):
	return lerp(a,b, 1-exp(-lambda * dt))

func _physics_process(delta: float) -> void:
	var flip := Input.is_action_just_pressed("ui_accept")
	for wheel: Wheel in wheels.get_children():
		var force = wheel.calculate_force()
		if force != Vector3.ZERO:
			apply_force(force, wheel.global_position - global_position)
		if flip:
			apply_force(global_basis.y * 10 * sign(wheel.position.x), wheel.global_position - global_position)
	if flip:
		apply_force(Vector3.UP * 100,Vector3.ZERO)

# Called when the node enters the scene tree for the first timwe.
func _ready() -> void:
	pass # Replace with function body.

var cur_speed := 0.0
var cur_dir := 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var in_speed = Input.get_axis("backward","forward") * 5
	cur_speed = damp(cur_speed,in_speed,0.99,delta)
	for wheel: Wheel in wheels.get_children():
		wheel.cur_speed = cur_speed
	var in_dir = Input.get_axis("right","left") * 60
	cur_dir = move_toward(cur_dir,in_dir,delta*250)
	$wheels/fl.rotation_degrees.y = cur_dir
	$wheels/fr.rotation_degrees.y = cur_dir
	
	if Input.is_action_just_pressed("update_terrain"):
		# todo move this to input function
		write_terrain_to_file()

@onready var distance_timer: Timer = $distanceTimer
@onready var distance_sensors: Node3D = $distanceSensors

var terrain_points: Array[Vector3] = []

func _on_timer_timeout() -> void:
	var new_point_count := 0
	for distance_sensor: RayCast3D in distance_sensors.get_children():
		if not distance_sensor.is_colliding():
			continue
		var collision_point := distance_sensor.get_collision_point()
		var valid := true
		for point: Vector3 in terrain_points:
			if (point-collision_point).length_squared() < (0.5*0.5):
				valid = false
				break
		if valid:
			terrain_points.append(collision_point)
			new_point_count+=1
	print_debug("new points: ",new_point_count)
	distance_timer.start()

func write_terrain_to_file():
	var app_dir = "user://vertices.txt"
	var file := FileAccess.open(app_dir,FileAccess.WRITE)
	var cur_string := ""
	var line_length = 0
	for vertex: Vector3 in terrain_points:
		var x_str = ("-%015.10f" % abs(vertex.x)) if vertex.x < 0 else ("0%015.10f" % vertex.x)
		var y_str = ("-%015.10f" % abs(vertex.y)) if vertex.y < 0 else ("0%015.10f" % vertex.y)
		var z_str = ("-%015.10f" % abs(vertex.z)) if vertex.z < 0 else ("0%015.10f" % vertex.z)
		var line = "%s,%s,%s\n" % [x_str, y_str, z_str]
		cur_string += line
		if line_length == 0:
			line_length = line.length()
		elif line.length() != line_length:
			print_debug("lines are different sizes!")
	file.store_string(cur_string)
	print("path: "+file.get_path_absolute())
	print("line length: "+str(line_length))
