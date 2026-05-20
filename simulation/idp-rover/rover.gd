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

const max_terrain_points := 10000
var terrain_points: Array[Vector3] = []
var new_point_count := 0

func _on_timer_timeout() -> void:
	new_point_count = 0
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
	#print_debug("new points: ",new_point_count,", point count: ",len(terrain_points))
	while len(terrain_points) > max_terrain_points:
		terrain_points.pop_front()
	distance_timer.start()

@export var debug_marker:PackedScene

func write_terrain_to_file():
	print_debug("\nbeginning everything")
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
	var vertex_file_path = file.get_path_absolute()
	file.close()
	print("path: "+vertex_file_path)
	print("line length: "+str(line_length))
	var temp_file := FileAccess.open("user://heightmap.roverheightmap",FileAccess.WRITE)
	var heightmap_path := temp_file.get_path_absolute()
	temp_file.close()
	print("output path: "+heightmap_path)
	
	# execute programs
	var output = []
	#var exit_code = OS.execute(
		#"C:/Users/zacha/Documents/programms/idp-mars-rover/triangulation/heightmap.exe",
		#[vertex_file_path, heightmap_path],
		#output,
		#true
	#)
	# todo find out why powershell is needed
	var command = "\"C:/Users/zacha/Documents/programms/idp-mars-rover/triangulation/heightmap.exe %s %s\"" % [vertex_file_path,heightmap_path]
	print("command: ",command)
	OS.execute("powershell.exe",["-Command",command],output,true)
	#print("exit code: ",exit_code)
	var real_output = ""
	for out:String in output:
		for line in out.split("\n"):
			real_output=line
			if line.contains("Point"):
				continue
			print(line)
	if not real_output.begins_with("run"): # todo come up with something better
		print_debug("super fail!")
		return
	
	var temp_file_2 := FileAccess.open("user://path.roverpath",FileAccess.WRITE)
	var path_path := temp_file_2.get_path_absolute()
	temp_file_2.close()
	print("path path: "+path_path)
	
	var command_2 = "\"C:/Users/zacha/Documents/programms/idp-mars-rover/pathfinding/pathfind.exe %s %s %f %f %f %f\"" % [heightmap_path,path_path,global_position.x,global_position.z,0,0]
	output = []
	OS.execute("powershell.exe",["-Command",command_2],output,true)
	real_output = ""
	for out:String in output:
		for line in out.split("\n"):
			real_output=line
			print(line)
	if not real_output.begins_with("success"):
		print_debug("super fail 2!")
		return
	
	var points: Array[Vector3] = []
	var path_file := FileAccess.open("user://path.roverpath",FileAccess.READ)
	
	while path_file.get_position() < path_file.get_length():
		var line := path_file.get_line().strip_edges()
		
		if line.is_empty():
			continue
			
		var parts := line.split(",")
		
		if parts.size() == 3:
			var x := parts[0].to_float()
			var y := parts[1].to_float()
			var z := parts[2].to_float()
			
			points.append(Vector3(x, y, z))
		else:
			push_warning("Skipping malformed line: " + line)
			
	path_file.close()
	
	for child in $temp_Debug.get_children():
		child.queue_free()
	
	for point:Vector3 in points:
		var new_thing:MeshInstance3D = debug_marker.instantiate()
		$temp_Debug.add_child(new_thing)
		new_thing.global_position = point
		new_thing.global_position.y += 1
		new_thing.top_level = true
	
	print()
